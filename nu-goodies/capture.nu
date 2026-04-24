use history.nu [ get-last-commands-from-sql ]
use str.nu [ "str c" "to-safe-filename" ]

# Capture recent commands from Wezterm scrollback with ANSI codes
export def 'wez-to-ansi' []: nothing -> string {
    ^wezterm cli get-text --escapes
}

# Record Wezterm session to asciicast format
export def 'wez-to-asciicast' [
    command: string = '' # Command to record
    --filename: path # Output file path (unused)
]: nothing -> path {
    let err = ^wezterm record --cwd (pwd) -- $nu.current-exe --execute $'source $nu.env-path; clear; ($command)'
        | complete
        | get stderr

    let wezrec = $err
        | str replace -r '\s+$' ''
        | parse -r '(?<path>\S+$)'
        | get path.0

    let target_folder = '~/temp/wezterm-asciinemas'
        | path join $'gif_(pwd | path split | last)'
        | $'($in)(mkdir $in)'

    try { mv $wezrec $target_folder } catch { print "wasn't moved, the original err with path is:" $err }

    $target_folder | path join ($wezrec | path basename)
}

# Record Wezterm session and convert to GIF
export def 'wez-to-gif' [
    --filename: path # Output GIF path
    --font-family: string = "ZedMono Nerd Font" # Font for rendering
    --font-size: int = 20 # Font size in pixels
]: nothing -> nothing {

    let wezrec = wez-to-asciicast

    let gif_name = $wezrec
        | path dirname
        | path join (
            $filename
            | default $'_wez_gif_(date now | format date `%s`).gif'
        )

    ^agg --font-family $font_family --font-size $font_size -v $wezrec $gif_name
    print ''

    ^open -R $gif_name # Reveal in Finder
}

# Capture wezterm scrollback, split by prompts, output chosen ones to an image file
# Uses nu_plugin_image
# https://wezfurlong.org/wezterm/index.html
# https://github.com/FMotalleb/nu_plugin_image/

# use wez-to-ansi.nu

def 'default-image-path' [
    filename: string
]: nothing -> path {
    ['~/temp/freeze_images/' (pwd | path split | last)]
    | path join
    | $'($in)(mkdir $in)'
    | path join $filename
}

def 'ansi-to-png' [
    output_path: path
]: string -> nothing {
    let ans_path = $output_path | str replace -a '.png' '.ans'
    $in | save -f $ans_path
    if (which 'to png' | is-not-empty) {
        nu --plugin-config $nu.plugin-path -c $"open --raw ($ans_path) | to png ($output_path) --font IosevkaFont"
    }
    ^open -R $output_path
}

# Capture wezterm scrollback, split by prompts, output chosen ones to an image file
export def 'wez-to-png' [
    n_last_commands: int = 2 # Number of recent commands (and outputs) to capture.
    --output-path: path = '' # Path for saving output images.
]: nothing -> nothing {
    let output_path = $output_path
        | if $in != '' { } else {
            let filename = last-commands $n_last_commands
                | to-safe-filename --prefix 'wez-out-' --suffix '.png' --date

            default-image-path $filename
        }

    wez-to-ansi | ansi-to-png $output_path
}

def 'last-commands' [
    n_last_commands: int
]: nothing -> string {
    get-last-commands-from-sql ($n_last_commands + 1)
    | drop 1
    | str trim
    | str join '_'
}

def 'completions-copy-out' []: nothing -> list<record<value: int, description: string>> {
    if ($nu.history-path | str ends-with 'txt') { return [] }

    let session = history session
    let width = term size | get columns | $in - 5

    open $nu.history-path
    | query db "SELECT command_line FROM history WHERE session_id = ? ORDER BY id DESC LIMIT 20" -p [$session]
    | get command_line
    | enumerate
    | each {|i|
        {
            value: ($i.index + 1)
            description: ($i.item | str replace -a (char nl) '·' | str substring --grapheme-clusters 0..$width)
        }
    }
}

def 'zellij-dump-prompts' [
    indices: list<int>
    --name: string = 'scrollback'
]: nothing -> record<raw_lines: list<string>, reversed_prompts: list<int>> {
    let tmp = $nu.temp-dir | path join $'($name).txt'
    zellij action dump-screen --path $tmp --full

    let raw_lines = open $tmp | lines
    let stripped = $raw_lines | each { ansi strip }

    let prompts = $stripped
        | enumerate
        | where { $in.item =~ '^> ' }
        | get index

    let max_n = $indices | math max
    if ($prompts | length) < ($max_n + 1) {
        error make --unspanned {msg: $'Not enough commands in scrollback \(need ($max_n + 1) prompts\)'}
    }

    {raw_lines: $raw_lines reversed_prompts: ($prompts | reverse)}
}

def 'extract-by-prompts' [
    indices: list<int>
    lines: list<string>
    reversed_prompts: list<int>
    --flatten
]: nothing -> list<string> {
    if ($indices | length) == 1 {
        let start = $reversed_prompts | get ($indices | first)
        let end = $reversed_prompts | get 0

        $lines
        | skip $start
        | first ($end - $start)
    } else if $flatten {
        $indices
        | each {|n|
            let start = $reversed_prompts | get $n
            let end = $reversed_prompts | get ($n - 1)

            $lines
            | skip $start
            | first ($end - $start)
        }
        | flatten
    } else {
        $indices
        | each {|n|
            let start = $reversed_prompts | get $n
            let end = $reversed_prompts | get ($n - 1)

            $lines
            | skip $start
            | first ($end - $start)
            | str join (char nl)
        }
        | str join "\n\n"
        | lines
    }
}

# Look up a command in session history by matching its first line
def 'match-history-command' [
    first_line: string
]: nothing -> any {
    if ($nu.history-path | str ends-with 'txt') { return null }

    let session = history session
    let match = open $nu.history-path
        | query db "SELECT command_line FROM history WHERE session_id = ? ORDER BY id DESC LIMIT 100" -p [$session]
        | get command_line
        | where { ($in | lines | first | str trim -r) == ($first_line | str trim -r) }
        | get 0?

    if ($match == null) { return null }
    {command: $match line_count: ($match | lines | length)}
}

# Format a scrollback block (command + output) using history-assisted splitting
def 'format-block' [
    block: list<string>
    no_comment: bool
]: nothing -> string {
    if $no_comment {
        return ($block | str join (char nl))
    }

    let cmd_first_line = $block | first | str replace -r '^> ' ''
    let hist = match-history-command $cmd_first_line

    if ($hist != null) {
        let command_text = $hist.command | lines
        let output = $block | skip $hist.line_count
            | each {
                if ($in | is-empty) { } else { str c '# => ' $in }
            }
        $command_text | append $output | str join (char nl)
    } else {
        print -e "note: command not found in history, outputting raw"
        $block | each { str replace -r '^> ' '' } | str join (char nl)
    }
}

# Copy command(s) with output to clipboard from Zellij pane scrollback
#
# > copy-out 3     # from 3rd-to-last command through the last
# > copy-out 3 1   # 3rd-to-last and last, separately
export def 'copy-out' [
    ...rest: int@completions-copy-out # Command indices (1 = last)
    --echo (-e) # Return text instead of copying
    --ansi (-a) # Keep ANSI escape codes
    --no-comment (-C) # Don't comment output with # =>
]: nothing -> any {
    let indices = $rest | if ($in | is-empty) { [1] } else { }

    let dump = zellij-dump-prompts $indices --name 'copy-out'
    let output_lines = $dump.raw_lines
        | if $ansi { } else { each { ansi strip } }

    # Build per-command blocks for history-assisted formatting
    let block_indices = if ($indices | length) == 1 {
        1..($indices | first) | each {} | reverse
    } else {
        $indices
    }

    $block_indices
    | each {|n|
        let start = $dump.reversed_prompts | get $n
        let end = $dump.reversed_prompts | get ($n - 1)
        $output_lines | skip $start | first ($end - $start)
    }
    | each {|block| format-block $block $no_comment }
    | str join "\n\n"
    | str replace -ra '\n+$' ''
    | if $echo { } else { pbcopy }
}

# Delete last N prompts with their outputs from Zellij pane scrollback
# Uses ANSI escapes to clear terminal lines; works for on-screen content
export def 'delete-prompts' [
    n: int = 1 # Number of prompts (with outputs) to delete
]: nothing -> nothing {
    let dump = zellij-dump-prompts [$n] --name 'delete-prompts'
    let reversed = $dump.reversed_prompts

    let target_line = $reversed | get $n
    let current_line = $reversed | get 0

    # Include the blank line before target prompt (transient prompt emits \n before "> ")
    let start = [($target_line - 1) 0] | math max
    let lines_up = $current_line - $start + 1

    print -n $"\e[($lines_up)A\e[0J"
}

# Capture commands from Zellij pane scrollback and render to PNG
#
# > zellij-to-png 3     # from 3rd-to-last command through the last
# > zellij-to-png 3 1   # 3rd-to-last and last, separately
export def 'zellij-to-png' [
    ...rest: int@completions-copy-out # Command indices (1 = last)
    --output-path: path = '' # Path for saving output image
]: nothing -> nothing {
    let indices = $rest | if ($in | is-empty) { [1] } else { }

    let dump = zellij-dump-prompts $indices --name 'zellij-to-png'

    let out = extract-by-prompts $indices $dump.raw_lines $dump.reversed_prompts --flatten
        | str join (char nl)

    let output_path = $output_path
        | if $in != '' { } else {
            let filename = last-commands ($indices | math max)
                | to-safe-filename --prefix 'zel-out-' --suffix '.png' --date

            default-image-path $filename
        }

    $out | ansi-to-png $output_path
}
