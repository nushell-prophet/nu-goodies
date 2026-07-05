use history.nu [ get-last-commands-from-sql ]
use str.nu [ "str c" "to-safe-filename" ]

# Capture recent commands from Wezterm scrollback with ANSI codes
export def 'wez-to-ansi' []: nothing -> string {
    ^wezterm cli get-text --escapes
}

# Record Wezterm session to asciicast format
export def 'wez-to-asciicast' [
    command: string = '' # Command to record
]: nothing -> path {
    let err = ^wezterm record --cwd (pwd) -- $nu.current-exe --execute $'source $nu.env-path; clear; ($command)'
        | complete
        | get stderr

    let wezrec = $err
        | str replace --regex '\s+$' ''
        | parse --regex '(?<path>\S+$)'
        | get path.0

    let target_folder = '~/temp/wezterm-asciinemas'
        | path join $'gif_(pwd | path split | last)'
        | tee { mkdir $in }

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
    | tee { mkdir $in }
    | path join $filename
}

const bg_presets = [
    '#0d0d0d' # near-black
    '#000000' # pure black (cozy sandbox background)
    '#ffffff' # white
    'transparent' # no background fill
]

# Render ANSI on stdin to a PNG file via ansisvg -> rsvg-convert.
# Returns the output path so callers can pass it to ^open or chafa.
export def 'ansi-to-png' [
    out?: path # Why: when omitted, auto-pick the next free img<N>.png in cwd
    --font-size: int = 50
    --font-name: string = 'ZedMono Nerd Font' # Why: matches wezterm config; rsvg-convert resolves via fontconfig after `brew install --cask font-zed-mono-nerd-font`
    --line-height: float = 1.0
    --background: string@$bg_presets = '#000000' # Why: matches the cozy sandbox background (black), set via `wezterm-cozy --background`
    --show
]: string -> path {
    let $out = $out | default (next_img_path)
    # Not ansisvg --fontfile + resvg because: resvg ignores SVG @font-face and CSS class selectors,
    # so colors collapse to grey. rsvg-convert (librsvg) handles both via fontconfig + simplecss.
    $in
    | ansisvg --transparent --fontname $font_name --fontsize $font_size --lineheight $line_height
    | rsvg-convert -b $background -o $out
    if $show { chafa $out }
    $out
}

def 'next_img_path' []: nothing -> string {
    let $nums = ls
        | get name
        | each {|n| $n | parse --regex `^img(?<n>\d+)\.png$` | get n.0? }
        | compact
        | each { into int }
    let $next = ($nums | append 0 | math max) + 1
    $'img($next).png'
}

# Idempotent installer for the four pieces ansi-to-png needs:
# ansisvg (no brew formula, fetched via go install + symlinked into brew prefix),
# librsvg for rsvg-convert, chafa, and the ZedMono Nerd Font cask.
export def 'install-deps' []: nothing -> nothing {
    if (which ansisvg | is-empty) {
        # Not brew because: ansisvg has no formula. Go install puts the binary in $GOPATH/bin;
        # symlink into brew prefix so it lands on the same PATH as the rest.
        if (which go | is-empty) {
            error make {msg: 'go required to install ansisvg; install go first'}
        }
        print 'installing ansisvg...'
        ^go install github.com/wader/ansisvg@latest
        let $src = ^go env GOPATH | str trim | path join 'bin' 'ansisvg'
        let $dst = ^brew --prefix | str trim | path join 'bin' 'ansisvg'
        ^ln -sf $src $dst
    }
    if (which rsvg-convert | is-empty) {
        print 'installing librsvg...'
        ^brew install librsvg
    }
    if (which chafa | is-empty) {
        print 'installing chafa...'
        ^brew install chafa
    }
    let $font_installed = [
        '~/.local/share/fonts/ZedMonoNerdFont-Extended.ttf'
        '~/Library/Fonts/ZedMonoNerdFont-Extended.ttf'
    ] | each { path expand } | any {|p| $p | path exists }
    if not $font_installed {
        print 'installing ZedMono Nerd Font...'
        ^brew install --cask font-zed-mono-nerd-font
    }
}

# Capture wezterm scrollback, split by prompts, output chosen ones to an image file
export def 'wez-to-png' [
    n_last_commands: int = 2 # Number of recent commands (and outputs) to capture.
    --output-path: path = '' # Path for saving output images.
]: nothing -> nothing {
    # Not `$output_path | if $in != '' { } else { }` because: 0.114 type-checks the block's
    # string input against `last-commands` (a `nothing -> string` command) and rejects it
    let output_path = if $output_path != '' { $output_path } else {
        let filename = last-commands $n_last_commands
            | to-safe-filename --prefix 'wez-out-' --suffix '.png' --date

        default-image-path $filename
    }

    wez-to-ansi | ansi-to-png $output_path | ^open -R $in
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
    | query db "SELECT command_line FROM history WHERE session_id = ? ORDER BY id DESC LIMIT 20" --params [$session]
    | get command_line
    | enumerate
    | each {|i|
        {
            value: ($i.index + 1)
            # Why: drop the ` #exit_<code>` tag dotfiles' hooks-config.nu adds to failed commands
            description: ($i.item | str replace --regex ' #exit_\d+$' '' | str replace --all (char nl) '·' | str substring --grapheme-clusters 0..$width)
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
        error make --unspanned {msg: $"Not enough commands in scrollback \(need ($max_n + 1) prompts\)"}
    }

    {raw_lines: $raw_lines reversed_prompts: ($prompts | reverse)}
}

# Slice scrollback lines between two prompts (indices into reversed_prompts)
def 'prompt-block' [
    lines: list<string>
    reversed_prompts: list<int>
    from: int
    to: int
]: nothing -> list<string> {
    let start = $reversed_prompts | get $from
    let end = $reversed_prompts | get $to

    $lines
    | skip $start
    | first ($end - $start)
}

def 'extract-by-prompts' [
    indices: list<int>
    lines: list<string>
    reversed_prompts: list<int>
    --flatten
]: nothing -> list<string> {
    if ($indices | length) == 1 {
        prompt-block $lines $reversed_prompts ($indices | first) 0
    } else if $flatten {
        $indices
        | each {|n| prompt-block $lines $reversed_prompts $n ($n - 1) }
        | flatten
    } else {
        $indices
        | each {|n| prompt-block $lines $reversed_prompts $n ($n - 1) | str join (char nl) }
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
        | query db "SELECT command_line FROM history WHERE session_id = ? ORDER BY id DESC LIMIT 100" --params [$session]
        | get command_line
        # Why: dotfiles' hooks-config.nu (pre_prompt) tags failed commands with
        # ` #exit_<code>` in history; strip it so the untagged on-screen command matches
        # (and stays out of the paste). If that hook goes away, drop this whole strip.
        | each { str replace --regex ' #exit_\d+$' '' }
        | where { ($in | lines | first | str trim --right) == ($first_line | str trim --right) }
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

    let cmd_first_line = $block | first | str replace --regex '^> ' ''
    let hist = match-history-command $cmd_first_line

    if ($hist != null) {
        let command_text = $hist.command | lines
        let output = $block | skip $hist.line_count
            | each {
                if ($in | is-empty) { } else { str c '# => ' $in }
            }
        $command_text | append $output | str join (char nl)
    } else {
        print --stderr "note: command not found in history, outputting raw"
        $block | each { str replace --regex '^> ' '' } | str join (char nl)
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
    --cwd # Include CWD into first line comment
]: nothing -> any {
    let indices = $rest | if ($in | is-empty) { [1] } else { }

    let dump = zellij-dump-prompts $indices --name 'copy-out'
    let output_lines = $dump.raw_lines
        | if $ansi { } else { each { ansi strip } }

    # Build per-command blocks for history-assisted formatting
    let block_indices = if ($indices | length) == 1 {
        ($indices | first)..1
    } else {
        $indices
    }

    $block_indices
    | each {|n|
        format-block (prompt-block $output_lines $dump.reversed_prompts $n ($n - 1)) $no_comment
    }
    | str join "\n\n"
    | str replace --all --regex '\n+$' ''
    | if $cwd { $"# $(pwd)\n($in)" } else { }
    | if $echo { } else { pbcopy }
}

# Open a new Zellij pane in the current tab running `nu --execute <command>`.
# Pane closes automatically when nushell exits (--close-on-exit).
export def 'in-pane' [
    command: string # Command to run in the new pane (nushell syntax; pipes allowed)
    --right (-r) # Split right instead of down
]: nothing -> nothing {
    let direction = if $right { 'right' } else { 'down' }
    zellij action new-pane --close-on-exit --direction $direction -- nu --execute $command | ignore
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

    print --no-newline $"\e[($lines_up)A\e[0J"
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

    let output_path = if $output_path != '' { $output_path } else {
        let filename = last-commands ($indices | math max)
            | to-safe-filename --prefix 'zel-out-' --suffix '.png' --date

        default-image-path $filename
    }

    $out | ansi-to-png $output_path | ^open -R $in
}
