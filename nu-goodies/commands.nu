###file L.nu
# Open table in Less
export def 'L' [
    --abbreviated (-a): int = 1000
    --bat (-b) # Use bat instead of less
]: any -> nothing {
    table -e --abbreviated $abbreviated | into string | if $bat { bat } else { less -R }
}

###file O.nu
def completions-macos-apps []: nothing -> list<string> {
    ls /Applications -s | get name | each { str replace '.app' '' | $'"($in)"' }
}

# Open a file in the specified macOS application or reveal it in Finder (--app flag supports completions)
# > O O.nu --app "Sublime Text"
export def 'O' [
    filepath?: path
    --app (-a): string@'completions-macos-apps' = 'Snagit 2022.app' # App to open with
    --reveal (-r) # Reveal app in Finder
]: [path -> nothing nothing -> nothing] {
    if $filepath == null { } else { $filepath }
    | if $reveal {
        ^open -R $in
    } else {
        ^open -a $app $in
    }
}

###file bar.nu
# use std repeat

# Construct bars based on a given percentage from a given width (5 is default)
#
# https://github.com/nushell/nu_scripts/blob/bar/sourced/progress_bar/bar.nu
# > bar 0.2
# █
#
# > bar 0.71
# ███▌
export def 'bar' [
    percentage: float
    --background (-b): string = 'default'
    --foreground (-f): string = 'default'
    --progress (-p) # Output the result using 'print -n'
    --width (-w): int = 5
]: nothing -> string {
    let blocks = [null "▏" "▎" "▍" "▌" "▋" "▊" "▉" "█"]
    let full_bar = $blocks | last
    let whole_part = ($percentage * $width) // 1
    | into int
    | seq 1 $in
    | each { $full_bar }
    | str join

    let fraction = $blocks
    | get (
        ($percentage * $width) mod 1
        | $in * ($blocks | length | $in - 1)
        | math round
    )

    let result = $"($whole_part)($fraction)"
    | fill --character ' ' -w $width
    | if ($foreground == 'default') and ($background == 'default') { } else {
        $"(ansi -e {fg: ($foreground) bg: ($background)})($in)(ansi reset)"
    }

    if $progress {
        print -n $"($result)\r"
    } else {
        $result
    }
}

###file bye.nu
# use gradient-screen.nu

# Display gradient screen and exit the shell
export def 'bye' [
    ...strings: string
    --no-date # Don't append date
    -n # don't quit
]: nothing -> nothing {
    gradient-screen ...$strings --no-date=$no_date
    if not $n { exit }
}

###file cb.nu
# Shortcut for pbpaste and pbcopy. But is it needed?
export def 'cb' [
    --paste
]: [any -> nothing nothing -> string] {
    if $paste or ($in == null) {
        pbpaste
    } else {
        pbcopy
    }
}

###file center.nu
# Center text within terminal width
export def 'center' [
    --factor: int = 1 # Divide terminal width by this factor
]: string -> string {
    fill -a center --width ((term size).columns // $factor)
}

###file copy-cmd.nu
# Copy this command to clipboard
export def 'copy-cmd' []: nothing -> nothing {
    let commands = history
    | last 2
    | get command
    | str trim

    $commands
    | last
    | if $in == 'copy-cmd' {
        $commands | first
    } else { }
    | str replace -r '\s*\| copy-cmd.*' ''
    | pbcopy
}

###file cprint.nu
# Print a string colorfully with bells and whistles
export def 'cprint' [
    text?: string # Text to format, if omitted stdin will be used
    --color (-c): string@'completions-colors' = 'default' # Color to use for the cprint text
    --highlight-color (-H): string@'completions-colors' = 'green_bold' # Color to use for highlighting text enclosed in asterisks
    --frame-color (-r): string@'completions-colors' = 'dark_gray' # Color to use for frame
    --frame (-f): string = '' # Symbol (or a string) to frame a text
    --lines-before (-b): int = 0 # Number of new lines before a text
    --lines-after (-a): int = 1 # Number of new lines after a text
    --echo (-e) # Echo text string instead of printing
    --keep-single-breaks # Don't remove single line breaks
    --width (-w): int = 80 # The total width of text to wrap it
    --indent (-i): int = 0 # Indent output by number of spaces
    --align: string = 'left' # Alignment of text
]: [string -> nothing nothing -> nothing nothing -> string string -> string] {
    let text = if $text == null { } else { $text }

    let width_safe = width-safe $width $indent

    $text
    | wrapit $keep_single_breaks $width_safe $indent
    | colorit $highlight_color $color
    | alignit $align $width_safe
    | if $frame != '' {
        frameit $width_safe $frame $frame_color
    } else { }
    | indentit $indent
    | newlineit $lines_before $lines_after
    | if $echo { } else { print -n $in }
}

# I `export` commands here to make them available for testing, while still
# keeping them in the same file so cprint can be easily copied to other projects

# Calculate safe text width accounting for terminal size and indent
export def 'width-safe' [
    width: int
    indent: int
]: nothing -> int {
    term size
    | get columns
    | [$in $width] | math min
    | $in - $indent
    | [$in 1] | math max # term size gives 0 in tests
}

# Wrap text to specified width, optionally preserving line breaks
export def 'wrapit' [
    keep_single_breaks: bool
    width_safe: int
    indent: int
]: string -> string {
    str replace -arm '^[\t ]+' ''
    | if $keep_single_breaks { } else { remove-single-nls }
    | str replace -arm '[\t ]+$' ''
    | str replace -arm $"\(.{1,($width_safe)}\)\(\\s|$\)|\(.{1,($width_safe)}\)" "$1$3\n"
    | str replace -r $'\s+$' '' # trailing new line
}

# Collapse single newlines into spaces, preserve double newlines as paragraphs
export def 'remove-single-nls' []: string -> string {
    str replace -r -a '(\n[\t ]*){2,}' '⏎'
    | str replace -arm '(?<!⏎)\n' ' ' # remove single line breaks used for code formatting
    | str replace -a '⏎' "\n\n"
}

# Add newlines before and after text
export def 'newlineit' [
    before: int
    after: int
]: string -> string {
    $"((char nl) | str repeat $before)($in)((char nl) | str repeat $after)"
}

# Wrap text with decorative frame lines above and below
export def 'frameit' [
    width_safe: int
    frame: string
    frame_color: string
]: string -> string {
    let input = $in

    $frame
    | str repeat $width_safe
    | str substring --grapheme-clusters 1..$width_safe # in case that frame has more than 1 chars
    | str c (ansi $frame_color) $in (ansi reset)
    | $in + "\n" + $input + "\n" + $in
}

# Apply color and highlight *emphasized* text
export def 'colorit' [
    highlight_color: string
    color: string
]: string -> string {
    str replace -r -a '\*([^*]+?)\*' $'(ansi reset)(ansi $highlight_color)$1(ansi reset)(ansi $color)'
    | str c (ansi $color) $in (ansi reset)
}

# Align each line of text within specified width
export def 'alignit' [
    alignment: string
    width_safe: int
]: string -> string {
    lines
    | fill --alignment $alignment --width $width_safe
    | str join (char nl)
}

# Add leading spaces to each line
export def 'indentit' [
    indent: int
]: string -> string {
    str replace -arm '^' (char sp | str repeat $indent)
}

def 'completions-colors' []: nothing -> list<string> {
    ansi --list | take until {|it| $it.name == reset } | get name
}

###file example.nu
# output a command from a pipe where `example` is used, and truncate the output table
#
# > ls nu-goodies | first 3 | reject modified | example
# ╭───────────name───────────┬─type─┬──size──╮
# │ nu-goodies/str.nu        │ file │ 1.4 KB │
# │ nu-goodies/cb.nu         │ file │  170 B │
# │ nu-goodies/abbreviate.nu │ file │  898 B │
# ╰───────────name───────────┴─type─┴──size──╯
export def 'example' [
    --no-copy (-C) # Don't copy the output into clipboard
    --no-comment (-H) # Don't comment the result
    --abbreviated: int = 10
    --bare # Don't wrap in `nu -c`, output the raw nushell command
]: any -> string {
    let input = table --abbreviated $abbreviated
    | if $no_comment { } else { into string | ansi strip }

    let command = get-last-commands-from-sql 1
    | str replace -r '\| example.*' ''
    | if $no_comment {
        nu-highlight # for making screnshots
    } else { }
    | if $bare { } else {
        if "'" not-in $in {
            # no single quotes — single-quote wrap (both shells)
            $"nu -c '($in)'"
        } else if ($in !~ '["$`\\]') {
            # only single quotes — double-quote wrap (both shells)
            $'nu -c "($in)"'
        } else {
            # both quotes or bash-unsafe chars — bash-only fallback
            $"nu -c '($in | str replace -a "'" "'\\''")'"
        }
    }
    | str c $in (char nl)

    $input
    | if $no_comment { } else {
        lines
        | each { str c '# => ' $in }
    }
    | prepend $command
    | str join (char nl)
    | if $no_copy { } else {
        tee { pbcopy }
    }
}

def get-last-commands-from-sql [n: int = 1]: nothing -> any {
    open $nu.history-path
    | query db "select command_line from history order by id desc limit ?" -p [$n]
    | get command_line
    | if $n == 1 {
        get 0
    } else { }
}

###file fill non-exist.nu
# Fill missing columns for each row
#
# This is how empty columns are represented
# > [{a: 1} {b: 2}] | to nuon
# [{a: 1}, {b: 2}]
#
# > [{a: 1} {b: 2}] | fill non-exist | to nuon
# [{a: 1, b: ""}, {b: 2, a: ""}]
export def 'fill non-exist' [
    value_to_replace: any = ''
]: table -> table {
    let table = $in

    $table
    | columns
    | reduce --fold $table {|i acc|
        $acc
        | default $value_to_replace $i
    }
}

###file format profile.nu
# use normalize.nu
# use bar.nu

# Format `debug profile` output
#
# > debug profile {pin-text cyber} --max-depth 7 --spans | format profile | null
export def 'format profile' []: table -> table {
    skip
    | update depth {|i| $i.depth - 1 }
    | normalize duration_ms
    | update duration_ms_norm { bar $in --width 16 }
    | if 'span' not-in ($in | columns) {
        error make --unspanned {msg: 'use debug profile --spans'}
    } else { }
    | insert fullspan {|i|
        view span $i.span.start $i.span.end
        | str replace -ar '(^|\n)\s+' ''
        | str substring 0..((term size).columns - 40 - ($i.depth * 2))
    }
    | insert hier {|i|
        seq 1 $i.depth
        | each { '│ ' }
        | str join
        | $in + "├─" + ($i.fullspan)
    }
    | sort-by id
    | reject span source fullspan parent_id id depth
}

###file gradient-screen.nu
# Fill screen with repeated texts from arguments or $env.gradient-screen.texts with random color gradient
export def --env gradient-screen [
    ...strings: string
    --no-date # Don't append date
    --echo
    --rows: int
]: nothing -> any {
    let strings = $strings
    | if $in == [] {
        $env.gradient-screen?.texts?
        | default [
            '<nushell<is<awesome<'
            '<wezterm<is<awesome<'
            'and<you<are<awesome<'
        ]
    } else { }

    let term_size = term size

    let screen_size = $term_size
    | if $rows == null { values } else {
        $in.columns * $rows
    }
    | math product

    let 1_list = $strings.0 | split chars
    let 1_len = $1_list | length
    let date_text = date now | format date "%Y%m%d_%H%M%S"

    let colors = rand-hex-col2

    $env.gradient-screen-last-colors = $colors

    let other_strings = $strings
    | skip
    | each {|i|
        str c $i ($1_list | last ($1_len - ($i | str length) mod $1_len) | str join)
    }
    | append ''

    let other_len = $other_strings
    | str length
    | math sum

    let n_chunks = ($screen_size - $other_len) // $1_len

    let base = seq 0 $n_chunks
    | each { $strings.0 }

    let output = $other_strings
    | reduce -f $base {|i acc|
        $acc
        | insert (random int 3..$n_chunks) $i
    }
    | str join
    | split chars --grapheme-clusters
    | first $screen_size
    | if $no_date { } else {
        drop ($date_text | str length)
        | append ($date_text | split chars)
    }
    | window $1_len --stride $1_len --remainder
    | each { str join | ansi gradient --fgstart $colors.0 --fgend $colors.1 }
    | str join

    split-ansi-chars $output
    | window $term_size.columns --stride $term_size.columns
    | each { str join }
    | str join (char nl)
    | $'($in)(ansi reset)'
    | if $echo { } else {
        print; sleep 2sec;
    }
}

# Show git commit dates for files, excluding bulk-change commits
export def ls-git-modified-date [
    path?: path
    --max-files-in-commit: int = 5 # skip commits with more than this number of files. Useful for excluding automatic changes such as those by prettier or ruff
]: nothing -> table {
    let path = $path | default { pwd }

    let gitlog = git log --all --format="===%ai" --name-only --diff-filter=ACMRT -- $path
    | $"\n($in)"
    | split row "\n==="
    | skip # skip the first empty group
    | each {|i|
        let lines = $i | lines

        let ts = $lines | first | into datetime

        $lines
        | skip 2
        | if ($in | length) <= $max_files_in_commit {
            each {|file| {name: $file commit-ts: $ts} }
        }
    }
    | compact
    | flatten
    | uniq-by name

    let path_candidate = git ls-files --full-name -- $path
    | lines
    | wrap name
    | join $gitlog name --inner

    let root = find-root

    let full_paths = $path_candidate | update name { [$root $in] | path join }

    try { $full_paths | update name { path relative-to (pwd) } } catch { $full_paths }
}

def split-ansi-chars [s: string]: nothing -> list<string> {
    # Pattern to match: escape sequence + one character (no reset needed for gradients)
    let pat = "(\e\\[[0-9;]*m)+(.)"

    let nul = char nul

    $s
    | str replace -ar $pat $'$1$2($nul)' # capture color + char, add delimiter
    | split row $nul
    | compact --empty
}

def generate-colors []: nothing -> list<int> { 1..3 | each { (random int 0..255) } }

def make-hex []: list<int> -> string { each { into binary --compact | encode hex } | prepend '0x' | str join }

def check-colors [c0: list<int> c1: list<int> --threshold: int = 250]: nothing -> bool {
    ($c0 | zip $c1 | each {|i| ($i.0 - $i.1) ** 2 } | math sum | math sqrt) > $threshold
}

def rand-hex-col2 []: nothing -> list<string> {
    # Try up to 30 times to find contrasting colors
    let pair = generate {|i = 0|
        if $i >= 30 { return {} }

        let c0 = generate-colors
        let c1 = generate-colors

        if (check-colors $c0 $c1) {
            {out: [$c0 $c1]}
        } else {
            {next: ($i + 1)}
        }
    }
    | get 0?

    # Fallback: force contrast if no good pair found
    $pair | default {
        let c0 = generate-colors
        let rand = random int 100..180
        [$c0 ($c0 | each { ($in + $rand) mod 255 })]
    }
    | each { make-hex }
}

###file hist.nu
alias core_hist = history
# use in-vd.nu

# Filter history with regex and convenient flags, add useful columns
export def 'hist' [
    like_filter?: string # a string to search in db
    --regex-filters: list<string> = [] # a regex to search for
    --entries: int = 5000 # A number of last entries to work with
    --all (-a) # Return all the history
    --session (-s) # Show only entries from the current session
    --cwd # Show only entries from the current folder
    --last-x: duration # Duration for the period to check commands
    --not-in-vd (-V) # Disable opening command in visidata
]: nothing -> any {
    # Start building the SQL query
    let sql_query = "
        SELECT command_line as command, start_timestamp / 1000 as start_timestamp, session_id, hostname, cwd,
        duration_ms / 1000000.0 as duration_s, exit_status FROM history WHERE 1=1
    "
    | if $like_filter != null {
        append $" AND command_line LIKE '%($like_filter)%'"
    } else { }
    | append " AND command_line NOT LIKE 'hist %'" # Build where clauses based on parameters Exclude 'hist' commands
    | append " AND exit_status = 0" # Only successful commands
    | if $session {
        # Session filter
        append $" AND session_id = (history session)"
    } else { }
    | if $cwd {
        # Folder filter
        append $" AND cwd = '(pwd)'"
    } else { }
    | if $last_x != null {
        # Time filter
        append $" AND start_timestamp > ((date now) - $last_x | into int)" # Convert to nanoseconds
    } else { }
    | append ' ORDER BY id DESC'
    | if not ($all or $entries == 0 or $like_filter != null) {
        append $" LIMIT ($entries)"
    } else { }
    | str join

    # Execute the query
    let results = open $nu.history-path | query db $sql_query

    # Apply regex filters in Nushell (SQLite doesn't support all regex features)
    let filtered_results = if $regex_filters == [] {
        $results
    } else {
        $regex_filters
        | reduce --fold $results {|pattern|
            where command =~ $pattern
        }
    }

    # Format timestamps as human readable
    # Convert nanoseconds to seconds and format
    # TODO: check that filtering by options is adjusted by offset too
    let formatted_results = $filtered_results | into datetime --format '%s' --offset (-3) start_timestamp

    # Add pipe count column
    $formatted_results
    | insert pipes {|i|
        # ast --flatten $i.command
        # | where shape == shape_pipe
        $i.command
        | parse -r '(\s\|)'
        | length
    }
    # Display in visidata or return
    | if $not_in_vd { } else { in-vd history }
}

# Save significant or all current session history entries into a .nu file. If the .nu file already exists, data will be appended.
export def 'hist-to-script' [
    filename?: path
    --dont-open (-O) # Don't open the saved history file in editor
    --up (-u): int = 0 # Set number of last events to save
    --all # Save all history into .nu file
    --directory-hist # Get history for a directory instead of session
]: nothing -> nothing {
    let session = history session

    let filepath = $filename
    | if ($in != null) { } else { $"history($session)" }
    | path parse
    | update extension 'nu'
    | path join

    let hist = history -l
    | if $directory_hist {
        where cwd == (pwd)
    } else {
        where session_id == $session
    }
    | get command
    | str replace -ar $';(char nl)\$.*? in-vd' ''
    | drop 1

    let buffer = $hist
    | if $up > 1 {
        last ($up + 1)
    } else if $all { } else {
        where {|i|
            $i =~ '(^(let|def|export) )|#|\b(save|source|mkdir|polars to-csv|polars to-avro|polars to-jsonl|polars to-arrow|polars to-parquet)\b'
        }
    }
    | str join "\n\n"
    | $"\n#($filepath)\n($in)\n#---\n"

    $buffer | save -a $filepath

    if not $dont_open {
        commandline edit -r $'($env.EDITOR) ($filepath)'
    }
}

###file in-fx.nu
# Convert data structure to JSON and open it in fx
export def --wrapped in-fx [
    ...rest
]: any -> nothing {
    to json -r
    | ansi strip
    | ^fx ...$rest
}

# Open data in Helix editor, return edited content to commandline
export def 'in-hx' [
    --path (-p) # Output file path instead of content
]: any -> nothing {
    let input = $in
    let type = $input | describe
    let filename = $nu.temp-path | path join (date now | format date "%Y%m%d_%H%M%S" | $in + '.nu')

    $input
    | if ($type =~ '(table|record|list)') { to nuon --indent 4 } else { }
    | if ($type =~ '(raw type|string)') { ansi strip } else { }
    | save $filename

    hx $filename

    if $path {
        print $path
    } else {
        commandline edit -r $"r######'(open $filename)'######"
    }
}

###file in-vd.nu
# https://github.com/nushell-prophet/nu-kv
use kv

# for other users use kv in nu-goodies
# use kv

# Open data in VisiData🔥
#
# The suitable format is detected automatically.
# If VisiData produces STDOUT, it will be assigned to $env.vd_temp.n
#
# Examples:
# > history | in-vd
export def 'in-vd' [
    --json (-j) # Force using msgpack for piping data in-vd
    --csv (-c) # Force using csv for piping data in-vd
]: any -> any {
    if ($in | describe | $in =~ 'FrameCustomValue') {
        polars into-nu
    } else { }
    | if $csv or not (($in | has_hier) or $json) {
        to csv
        | ansi strip
        | vd --save-filetype json --filetype csv -o -
        | complete
        | get stdout
    } else {
        to json --raw
        | vd --save-filetype json --filetype json -o -
        | complete
        | get stdout
    }
    | from json # vd will output the final sheet `ctrl + shift + q`
    | if ($in != null) {
        if ($in | columns) == [''] {
            get ''
        } else { }
        | kv set vd --return-to-stdout
    }
}

# Open nushell commands history in visidata
export def 'in-vd history' []: table -> nothing {
    where command !~ 'in-vd history'
    | to csv
    | vd --save-filetype csv --filetype csv -o -
    | complete
    | get stdout
    | if ($in == null) { return } else { }
    | from csv
    | get command
    | reverse
    | str join $'(char nl)'
    | str replace -r ';.+?\| in-vd;' ';'
    | commandline edit -r $in
}

# > [{a: b, c: d}] | has_hier
# false
# > [{a: {c: d}, b: e}] | has_hier
# true
def has_hier []: any -> bool {
    describe
    | find -r '^table(?!.*: (table|record|list))'
    | is-empty
}

###file ln-for-preview.nu
# Hard-link an input table to temp directory (useful for previewing files from large directories in external programs)
#
# > ls | where modified > (date now | $in - 20min) | ln-for-preview
export def --env ln-for-preview [
    --first: int = 500
]: [list -> nothing table -> nothing] {
    let input = $in
    let temp_path = [
        $nu.temp-path
        'hard_links'
        (date now | format date "%Y%m%d_%H%M%S")
    ]
    | path join

    mkdir $temp_path

    $input
    | first $first
    | if ($in | describe | $in =~ '^table') {
        if ($in | columns | 'name' in $in) {
            where type == file
            | get name
            | each { ln $in $temp_path }
        } else {
            error make {msg: 'no name column in input table'}
        }
    } else if ($in | describe | $in =~ '^list') {
        each { ln $in $temp_path }
    }

    cd $temp_path
}

###file main.nu
# source /Users/user/git/nu-goodies/nu-goodies/wez-to-ansi.nu
#dotnu-vars-end

# def main [ $n_last_commands: int = 2 --regex: string --lines_before_top_of_term: int --min_term_width: int ] {
#     ^wezterm cli get-text --escapes --start-line ($lines_before_top_of_term * -1)
#     | str replace -ra '(\r|\n)+$' ''
#     | lines
#     | skip until {|i| ($i | ansi strip) =~ $regex}
#     | split list --regex $regex
#     | drop
#     | last $n_last_commands
#     | flatten
#     | if $min_term_width == 0 { } else {
#         prepend (seq 1 $min_term_width | each {' '} | str join)
#     }
#     | str join (char nl)
# }

###file mc.nu
# Open Midnight Commander and cd to its exit directory
export def --env mc [
    path1?: path
    path2?: path
]: nothing -> nothing {
    let path = ($nu.temp-path | path join (random chars))
    if $path2 != null {
        ^mc --nosubshell $path1 $path2 -P $path
    } else if $path1 != null {
        ^mc --nosubshell $path1 -P $path
    } else {
        ^mc --nosubshell -P $path
    }
    if ($path | path exists) {
        cd (open -r $path)
        rm $path
    }
}

###file md.nu
# Create directory and cd into it
export def --env md [
    target_dir: string
    -d # Use standard directory
    --dest-dir: path = '/Users/user/temp'
]: nothing -> nothing {
    let dir = (
        if $d or ($dest_dir != '/Users/user/temp') {
            $dest_dir | path join ($target_dir | str replace -a ' ' '_')
        } else { $target_dir }
        | path expand
    )

    mkdir $dir
    if $env.ZELLIJ? != null {
        ^zellij action rename-tab ($target_dir | path basename)
    }
    cd $dir
}

###file mv1.nu
# Toggle suffix `_back` for a file
export def 'mv1' [
    file: path
]: nothing -> nothing {
    if ($file | str ends-with '_back') {
        mv $file $"($file | str replace -r '_back$' '')"
    } else {
        mv $file $'($file)_back'
    }
}

###file mygit log.nu
# Backup dotfiles and config directories to their git repos
export def 'mygit log' [
    --message (-m): string
]: nothing -> nothing {
    let message = $message
    | default (date now | format date "%Y-%m-%d")

    let dot_dir = '~/.config/dot_home_dir'
    | path expand

    $nu.home-dir
    | path join '.*'
    | glob $in -d 1 --no-dir --exclude ['.CFUserTextEncoding']
    | par-each {|i| cp --update $i $dot_dir }

    nu ~/.config/nushell/toolkit.nu history backup

    let paths = [
        '~/.config/nushell'
        '~/.config/'
        # '~/.visidata/'
    ]
    | path expand

    for $dir in $paths {
        try {
            print (ansi yellow) $dir (ansi reset) '';
            cd $dir;
            git add --all
            git commit -a -m $message
        }
    }
}

# history-backup moved to ~/.config/nushell/toolkit.nu

###file normalize.nu
# Normalize values in given columns
#
# > [[a b]; [1 2] [3 4] [a null]] | normalize a b
# ╭─a─┬─b─┬a_norm┬b_norm╮
# │ 1 │ 2 │ 0.33 │ 0.50 │
# │ 3 │ 4 │    1 │    1 │
# │ a │   │ a    │      │
# ╰───┴───┴──────┴──────╯
export def 'normalize' [
    ...column_names: string
    --suffix: string = '_norm'
]: table -> table {
    mut $table = ($in)
    let allowed_types = ['int' 'float' 'filesize']

    for column in $column_names {
        let max_value = $table
        | get $column
        | where ($it | describe | $in in $allowed_types)
        | math max

        $table = $table
        | upsert $'($column)($suffix)' {|i|
            $i
            | get $column
            | if ($in | describe | $in in $allowed_types) {
                $in / $max_value
            } else { }
        }
    }

    $table
}

###file nu-test.nu
# Install nushell or polars from the HEAD or the specified PR
export def 'nu-test install' [
    --nushell # Update nushell only
    --polars # Update polars plugin only
    --nushell-repo-path: path = '/Users/user/git/nushell/'
    --cargo-test-path: path = '/Users/user/.cargo_test/'
    --plugin-config: path = '/Users/user/.test_config/nushell/polars_test.msgpackz'
    --pr: string # A PR to checkout like ayax79:polars_pivot
]: nothing -> nothing {
    cd $nushell_repo_path

    git checkout main
    git pull

    if $pr != null {
        gh co $pr
    }

    mkdir $cargo_test_path
    $env.CARGO_HOME = $cargo_test_path

    # I install polars first to add it later to already updated nushell
    if $polars or not $nushell {
        cargo install --path ([$nushell_repo_path crates nu_plugin_polars] | path join)

        plugin add ([$cargo_test_path bin nu_plugin_polars] | path join) --plugin-config $plugin_config
        print 'test plugin updated' ''
    }

    if $nushell or not $polars {
        cargo install --path $nushell_repo_path
        print 'test nushell updated' ''
    }

    commandline edit -r $'^($cargo_test_path | path join bin nu) --plugin-config ($plugin_config)'
}

# Launch the test-installed Nushell binary
export def 'nu-test launch' [
    --no-plugin
]: nothing -> nothing {
    let exec = '/Users/user/.cargo_test/' | path join bin nu
    let params = [
        "--execute"
        "$env.PATH = ($env.PATH | prepend '/Users/user/.cargo_test/bin/')"
    ]
    | if $no_plugin { } else {
        prepend ['--plugin-config' '/Users/user/.test_config/nushell/polars_test.msgpackz']
    }

    ^$exec ...$params
}

const nightly_path = '~/temp/nu-nightly' | path expand

# Download and extract latest Nushell nightly build
export def --env download-nushell-nightly [
    --arch (-a): string = 'aarch64-apple-darwin' # Architecture as specified in nushell/nightly repo
    --ext (-e): string = '.tar.gz' # Extension, including the leading dot (e.g. '.tar.gz')
    --destination-dir (-d): directory = $nightly_path # Destination directory in which to save the download
]: nothing -> nothing {
    let most_recent_nightly = (http get https://api.github.com/repos/nushell/nightly/releases | get 0)
    let nightly_name = ($most_recent_nightly.name | str replace -r '^Nu-nightly-' '')
    let asset = http get $most_recent_nightly.assets_url
    | where name =~ $arch
    | where name =~ $'($ext)$'
    | get 0

    let filename = (
        $asset.name
        | str replace -r $ext $'-($nightly_name)($ext)'
        | str replace -r '^nu-' 'nu-nightly-'
    )

    let destination_file = ($destination_dir | path join $filename)

    print $"Downloading to:(char lf)($destination_file)"

    http get $asset.browser_download_url | save $destination_file
    tar -C $nightly_path -xzf $destination_file
}

# Launch the most recent downloaded nightly Nushell
export def 'launch-downloaded' []: nothing -> nothing {
    let path = glob ($nightly_path | path join *darwin *nu) | sort | last
    commandline edit -r $path
}

###file number-col-format.nu
# use number-format.nu

# Format number column in a table using number-format
#
# > [[a]; [123456.678] [2345.8900]] | number-col-format a --denom wt --decimals 2 --significant-digits 3
# ╭──────a───────╮
# │ 123_000.00wt │
# │   2_340.00wt │
# ╰──────────────╯
export def 'number-col-format' [
    column_name: string # A column name to format
    --thousands-delim (-t): string = '_' # Thousands delimiter: number-format 1000 -t ': 1'000
    --decimals (-d): int = 0 # Number of digits after decimal delimiter: number-format 1000.1234 -d 2: 1000.12
    --denom (-D): string = '' # Denom `--denom "Wt": number-format 1000 --denom 'Wt': 1000Wt
    --significant-digits: int = 0 # The number of first digits to display, others will become 0
]: table -> table {
    let input = $in

    if $column_name not-in ($input | columns) {
        error make {'msg': $'There is no ($column_name) in columns'}
    }

    let thousands_delim_length = $thousands_delim | str length --grapheme-clusters

    let integers = $input
    | get $column_name
    | math max
    | split row '.'
    | get 0
    | str length
    | if $thousands_delim_length > 0 {
        $in * ((3 + $thousands_delim_length) / 3 - 0.001) | math floor
    } else { }
    | append (
        $column_name | str length
        | $in - $decimals - $thousands_delim_length - ($denom | str length --grapheme-clusters)
    )
    | math max

    $input
    | upsert $column_name {|i|
        (
            number-format ($i | get $column_name)
            --denom $denom --decimals $decimals
            --thousands-delim $thousands_delim --integers $integers
            --significant-digits $significant_digits
        )
    }
}

###file number-format.nu
# use significant-digits.nu

# Format big numbers nicely
#
# > number-format 1000 --thousands-delim "'"
# 1'000
#
# > number-format 123 --integers 6
#    123
#
# > number-format 1000.1234 --decimals 2
# 1_000.12
#
# > number-format 1000 --denom 'Wt'
# 1_000Wt
export def 'number-format' [
    num?: number # Number to format
    --thousands-delim (-t): string = '_' # Thousands delimiter
    --integers (-i): int = 0 # Length of padding whole-part digits
    --significant-digits: int = 0 # The number of first digits to display, others will become 0
    --decimals (-d): int = 0 # Number of digits after decimal delimiter
    --denom (-D): string = '' # Denom
    --color: string = 'green'
]: [int -> string float -> string nothing -> string] {
    let in_num = $in

    let parts = $num
    | default $in_num
    | if $significant_digits == 0 { } else {
        significant-digits $significant_digits
    }
    | into string
    | split chars
    | split list '.'

    let whole_part = $parts.0
    | reverse
    | window 3 -s 3 --remainder
    | each { reverse | str join }
    | reverse
    | str join $thousands_delim
    | if $integers == 0 { } else {
        fill -w $integers -c ' ' -a r
    }

    let dec_part = if $decimals == 0 {
        ''
    } else {
        $parts.1?
        | default [0]
        | first $decimals
        | str join
        | '.' + $in
        | fill -w ($decimals + 1) -c '0' -a l
    }

    $"(ansi $color)($whole_part)($dec_part)(ansi reset)(ansi green_bold)($denom)(ansi reset)"
}

###file orbita.nu
# Generate 14 lines of spaces (placeholder grid)
export def 'orbita' []: nothing -> list<string> {
    1..14 | each { line ' ' }
}

def line [
    symbol: string
]: nothing -> string {
    1..61 | each { $symbol } | str join
}

###file print-and-pass.nu
# An alternative to `inspect` that doesn't break debugging output
export def 'print-and-pass' [
    callback?: closure
]: any -> any {
    let input = $in

    if $callback == null {
        print $input
    } else {
        print (do $callback $input)
    }

    $input
}

###file ramdisk-create.nu
# Create ramdisk in macOS
export def 'ramdisk-create' [
    size: filesize = 4194304kb
]: nothing -> nothing {
    let vol = (hdiutil attach -nobrowse -nomount $'ram://($size | into int | $in * 1.024 / 1000 * 2)' | str trim);
    sleep 2sec
    (^diskutil erasevolume HFS+ RAMDisk $vol)
    cd /Volumes/RAMDisk
}

###file select-i.nu
# https://discord.com/channels/601130461678272522/615253963645911060/1182672999921504336
# by @melmass at discord

# Interactively select columns from a table
export def 'select-i' []: table -> nothing {
    let tgt = $in
    let choices = $tgt
    | columns
    | input list -m "Pick columns to get: "
    | str join " "

    history
    | last
    | get command
    | str replace 'select-i' $'select ($choices)'
    | commandline edit -r $in
}

###file side-by-side.nu
# Display two tables side by side for comparison
export def 'side-by-side' [
    r: any # Right side table
    --delimiter: string = ' ' # Separator between columns
    --collapse # Use compact table format
    --l-header: string # Left table header label
    --r-header: string # Right table header label
]: any -> string {
    mut $l = $in | if $collapse { table } else { table -e } | into string | lines
    mut $r = $r | if $collapse { table } else { table -e } | into string | lines

    if $l == $r {
        print 'equal!'
    }

    if $l_header != null or $r_header != null {
        $l = ([$" (ansi yellow)($l_header)(ansi reset) "] | append $l)
        $r = ([$" (ansi yellow)($r_header)(ansi reset) "] | append $r)
    }

    let l_strip = $l | ansi strip
    let l_str_len_max = $l_strip | str length --grapheme-clusters | math max
    let l_n_lines = $l_strip | length

    let r_strip = $r | ansi strip
    let r_str_len_max = $r_strip | str length --grapheme-clusters | math max
    let r_n_lines = $r_strip | length

    let res = $l | append (
        seq 1 ($r_n_lines - $l_n_lines)
        | each { seq 1 $l_str_len_max | each { ' ' } | str join }
    )
    | each { fill --width $l_str_len_max }
    | zip (
        $r | append (
            seq 1 ($l_n_lines - $r_n_lines)
            | each { '' }
        )
    )
    | each {|i| $i.0 + $delimiter + $i.1 }
    | str join (char nl)

    let width = term size | get columns

    $res
    | if ($r_str_len_max + $l_str_len_max + ($delimiter | str length)) > $width {
        lines
        | ansi strip
        | str substring 0..$width --grapheme-clusters
        | str join (char nl)
    } else { }
}

###file significant-digits.nu
# The same version as https://github.com/nushell/nu_scripts/blob/significant-digits/stdlib-candidate/std-rfc/math/mod.nu

# Replace all insignificant digits with 0
#
# | Significant Digits | Maximum Relative Error |
# |--------------------|------------------------|
# | 1                  | 50%                    |
# | 2                  | 5%                     |
# | 3                  | 0.5%                   |
# | 4                  | 0.05%                  |
# | 5                  | 0.005%                 |
# | 6                  | 0.0005%                |
#
# > 0.0000012346789 | significant-digits 2
# 0.0000012
#
# > 1.2346789 | significant-digits 3
# 1.23
#
# > 123456789.89 | significant-digits 5
# 123450000
#
# > 1sec / 3 | significant-digits
# 333ms
export def 'significant-digits' [
    n: int = 3 # a number of significant digits
]: [int -> int float -> float duration -> duration] {
    let input = $in
    let type = $input | describe

    let num = match $type {
        'duration' => { $input | into int }
        _ => { $input }
    }

    let insignif_position = $num
    | if $in == 0 {
        0 # it's impoosbile to calculate `math log` from 0, thus 0 errors here
    } else {
        math abs
        | math log 10
        | math floor
        | $n - 1 - $in
    }

    # See the note below the code for an explanation of the construct used.
    let scaling_factor = 10 ** ($insignif_position | math abs)

    let res = $num
    | if $insignif_position > 0 {
        $in * $scaling_factor
    } else {
        $in / $scaling_factor
    }
    | math floor
    | if $insignif_position <= 0 {
        $in * $scaling_factor
    } else {
        $in / $scaling_factor
    }

    match $type {
        'duration' => { $res | into duration }
        'int' => { $res | into int }
        _ => { $res }
    }
}

# I started with `10.0 ** $insignif_position`, but it was sometimes producing
# not rounded digits in `$num / $scaling_factor` if `$insignif_position` was negative
# like with
# > 3456789 | math round --precision -5
# 3499999.9999999995
# so I use what I have now.

###file str.nu

alias std_append = append
alias std_prepend = prepend

# Repeat a string n times
export def 'str repeat' [
    n: int
]: string -> string {
    let text = $in
    seq 1 $n | each { $text } | str join
}

# Append strings with optional separators
export def 'str append' [
    ...text: string
    --space (-s)
    --2space (-2)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # Input and rest concatenator
    --rest-el: string = ' ' # Rest elements concatenator
]: string -> string {
    let input = $in
    let concatenator = $"(
        if $new_line { (char nl) }
    )(
        if $tab { (char tab) }
    )(
        if $2space { '  ' }
    )(
        if $space { ' ' }
    )(
        $concatenator
    )"

    $"($input)($concatenator)($text | str join $rest_el)"
}

# Prepend strings with optional separators
export def 'str prepend' [
    ...text: string
    --space (-s)
    --2space (-2)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # Input and rest concatenator
    --rest-el: string = ' ' # Rest elements concatenator
]: string -> string {
    let input = $in
    let concatenator = $"(
        if $new_line { (char nl) }
    )(
        if $tab { (char tab) }
    )(
        if $2space { '  ' }
    )(
        if $space { ' ' }
    )(
        $concatenator
    )"

    $"($text | str join $rest_el)($concatenator)($input)"
}

# Add indentation to text (not implemented)
export def 'indent' []: string -> string { $in }

# Remove indentation from text (not implemented)
export def 'dedent' []: string -> string { $in }

# Escape regex special characters in a string
export def 'escape-regex' []: string -> string {
    let input = $in
    let regex = '\.^$*+?{}()[]|/' | split chars | each { $'\($in)' } | str join '|' | $"\(($in))"

    $input | str replace --all --regex $regex '\$1'
}

# Escape Nushell special characters for string interpolation
export def 'escape-nushell-escapes' []: string -> string {
    str replace --all --regex '(\\|\"|\/|\(|\)|\{|\}|\$|\^|\#|\||\~)' '\$1'
}

###file testcd.nu
# Test helper for cd command
export def --env 'testcd' [destination: path]: nothing -> nothing { cd $destination }

# Convert string to filesystem-safe filename
export def 'to-safe-filename' [
    --prefix: string = '' # Prepend to filename
    --suffix: string = '' # Append to filename
    --regex: string = '[^A-Za-z0-9_А-Яа-я+]' # Characters to replace
    --date # Prepend timestamp for uniqueness
]: string -> string {
    str replace -ra $regex '_'
    | str replace -ra '__+' '_'
    | if $date {
        $'(now-fn)+($in | str substring ..30)' # make string uniq
    } else if (($in | str length) > 30) {
        $'($in | str substring ..30)($in | hash sha256 | str substring ..10)' # make string uniq
    } else { }
    | str c $prefix $in $suffix
}

###file to-temp-file.nu
# author @CabalCrow
# https://discord.com/channels/601130461678272522/615253963645911060/1247651613531705436

# <() from bash.
#
# The closure parameter is used, or the string stdin. Can take both applying
# the stdin first. If no stdin is used closure takes no argument & the output is
# used as the file content. If there is stdin closure takes the file name as an
# argument & operates on it.
export def 'to-temp-file' [
    content?: any # Commands used to generate the content of the file.
]: [any -> path nothing -> path] {
    let content = if $content == null { } else { $content }
    let output_file = $nu.temp-path
    | path join $'(date now | into int).yaml'

    $content | save $output_file

    $output_file
}

###file transcribe.nu
# Transcribe audio file to text using whisper.cpp
export def 'transcribe' [file: path]: nothing -> nothing {
    let file = $file
    | if $in =~ '\.wav$' { } else {
        let f = $in + '.wav';
        ffmpeg -i $file -ar 16000 $f;
        $f
    }

    (
        ^/Users/user/git/whisper.cpp/build/bin/whisper-cli -f $file
        -m /Users/user/git/whisper.cpp/models/ggml-base.en.bin
        -otxt $'($file).txt' -osrt $'($file).srt' -np
    )
}

###file wez-to-ansi.nu
# Capture recent commands from Wezterm scrollback with ANSI codes
export def 'wez-to-ansi' [
    n_last_commands: int = 2 # Number of recent commands (and outputs) to capture.
    --regex: string = '^>' # Regex to separate prompts from outputs. Default is ''.
    --lines-before-top-of-term: int = 100 # Lines from top of scrollback in Wezterm to capture.
    --min-term-width: int = 0 # Minimum output width (pads with spaces)
]: nothing -> string {

    # let regex = '^' + (ansi green_italic) + '>'

    ^wezterm cli get-text --escapes --start-line ($lines_before_top_of_term * -1)
    | str replace -a $"\n(ansi blue_bold)> " "\n>"
    | str replace -ra '(\r|\n)+$' ''
    | inspect
    | lines
    | skip until {|i| $i =~ $regex }
    | split list --regex $regex
    | drop
    | last $n_last_commands
    | flatten
    | if $min_term_width == 0 { } else {
        prepend (seq 1 $min_term_width | each { ' ' } | str join)
    }
    | str join (char nl)
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

    let target_folder = '/Users/user/temp/wezterm-asciinemas'
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

###file wez-to-png.nu
# Capture wezterm scrollback, split by prompts, output chosen ones to an image file
# Uses nu_plugin_image
# https://wezfurlong.org/wezterm/index.html
# https://github.com/FMotalleb/nu_plugin_image/

# use wez-to-ansi.nu

# Capture wezterm scrollback, split by prompts, output chosen ones to an image file
export def 'wez-to-png' [
    n_last_commands: int = 2 # Number of recent commands (and outputs) to capture.
    --output-path: path = '' # Path for saving output images.
]: nothing -> nothing {
    let output_path = $output_path
    | if $in != '' { } else {
        let filename = last-commands $n_last_commands
        | to-safe-filename --prefix 'wez-out-' --suffix '.png' --date

        ['/Users/user/temp/freeze_images/' (pwd | path split | last)]
        | path join
        | $'($in)(mkdir $in)'
        | path join $filename
    }

    let out = wez-to-ansi $n_last_commands

    $out | freeze --config user -o ($output_path | str replace -a '.png' '.svg')
    $out | freeze --config user -o ($output_path | str replace -a '.png' '.webp')
    $out | freeze --config user -o $output_path
    $out | save -f ($output_path | str replace -a '.png' '.ans')
    # | to png $output_path

    ^open -R $output_path
}

def 'now-fn' []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}

def 'last-commands' [
    n_last_commands: int
]: nothing -> string {
    history
    | last ($n_last_commands + 1)
    | drop # drop the last command to initiate image capture
    | get command
    | str trim
    | str join '_'
}

# Helper function to get all unique directories from command history
# Now with SQL-level filtering against dead_cwds
def 'get-history-dirs' [
    --include-dead (-d) # Include nonexistent directories in the results
]: nothing -> list<string> {
    # Ensure dead_cwds table exists
    init-dead-cwds-table

    if $include_dead {
        # Return all directories without filtering
        open $nu.history-path
        | query db "SELECT DISTINCT(cwd) FROM history ORDER BY id DESC"
        | get cwd
        | compact
    } else {
        # Return only directories that are not in dead_cwds table
        open $nu.history-path
        | query db "SELECT DISTINCT(h.cwd) FROM history h
                   LEFT JOIN dead_cwds d ON h.cwd = d.path
                   WHERE d.path IS NULL
                   ORDER BY h.id DESC"
        | get cwd
        | compact
    }
}

# Helper function to initialize dead_cwds table if it doesn't exist
def 'init-dead-cwds-table' []: nothing -> nothing {
    open $nu.history-path
    | query db "CREATE TABLE IF NOT EXISTS dead_cwds (path TEXT PRIMARY KEY, added_date TEXT DEFAULT CURRENT_TIMESTAMP)"
}

# Helper function to add a dead directory to the table
def 'add-dead-dir' [
    dir: string # Directory to add to dead dirs list
]: nothing -> nothing {
    # Insert new directory if it doesn't exist (parameterized to prevent SQL injection)
    open $nu.history-path
    | query db "INSERT OR IGNORE INTO dead_cwds (path) VALUES (?)" -p [$dir]
}

# Scan history directories and rebuild the dead_cwds table with non-existent paths
def 'update-dead-dirs' []: nothing -> list<string> {
    # Get all directories including those already marked as dead
    let all_cwds = get-history-dirs --include-dead

    # Check which directories no longer exist
    let dead_cwds = $all_cwds
    | where {|dir| $dir | path exists | not $in }

    # Clear existing dead_cwds table and insert new values
    # (table already initialized by get-history-dirs above)
    open $nu.history-path
    | query db "DELETE FROM dead_cwds"

    # Insert each dead directory
    $dead_cwds | each {|dir|
        add-dead-dir $dir
    }

    $dead_cwds
}

# Find first existing path from candidates, recording dead ones along the way
def 'find-first-existing' [
    candidates: list<string>
]: nothing -> string {
    $candidates
    | par-each --keep-order {|path|
        if ($path | path exists) {
            $path
        } else {
            add-dead-dir $path
            null
        }
    }
    | compact
    | get 0?
}

# Select a directory path using fuzzy search
def 'select-dir' [
    query: string # The search query
    --interactive (-i) # Force interactive mode
]: nothing -> string {
    let valid_cwds = get-history-dirs | to text

    if ($query | path exists) {
        return $query
    }

    if $interactive {
        return ($valid_cwds | fzf --scheme=path -q $query)
    }

    # Try fuzzy finding first
    let candidates = $valid_cwds | fzf -f $query | lines | first 10
    let existing_path = find-first-existing $candidates

    if ($existing_path | is-empty) {
        # Fall back to interactive
        $valid_cwds | fzf --scheme=path -q $query
    } else {
        $existing_path
    }
}

# Helper function to get open Zellij tab names
def 'zellij-tab-names' []: nothing -> list<string> {
    if ($env.ZELLIJ? | is-empty) { return [] }
    zellij action query-tab-names | lines
}

# Generate regex pattern to match Zellij tab by directory name
# Matches "dirname" or "dirname·2" (indexed duplicates)
def 'zellij-tab-pattern' [dir_name: string]: nothing -> string {
    $"^($dir_name)\(·|$\)"
}

# Handle Zellij tab navigation: create new tab, switch to existing, or rename current.
# Returns true if caller should cd (Zellij renamed tab), false if Zellij handled navigation.
def 'zellij-navigate' [
    path: string # Target directory path
    dir_name: string # Directory name for tab
    --new-tab (-n) # Open in new tab
]: nothing -> bool {
    if ($env.ZELLIJ? | is-empty) { return true }

    if $new_tab {
        # Create new tab with the directory
        zellij action new-tab --layout compact-bar-up --cwd $path --name $dir_name
        return false
    }

    # Check if tab with this name already exists
    let matching_tab = zellij-tab-names
    | where { $in =~ (zellij-tab-pattern $dir_name) }
    | get 0?

    let request: closure = {
        [
            {value: true description: 'switch to existing tab'}
            {value: false description: 'stay here'}
        ]
        | input list 'there is zellij tab already' --display description
        | get value
    }

    if ($matching_tab | is-not-empty) and (do $request) {
        # Switch to existing tab
        zellij action go-to-tab-name $matching_tab
        return false
    }

    # Rename current tab
    zellij action rename-tab $dir_name
    true
}

# Jump to directory from history using fuzzy search
export def --env 'z' [
    query?: string@'completions-cwds' # Fuzzy search query for directory
    --interactive (-i) # Always show interactive picker
    --new-tab (-n) # Open in new Zellij tab
    --update-dead-dirs (-u) # Rebuild nonexistent directories cache
]: nothing -> nothing {
    # Handle update dead dirs
    if $update_dead_dirs {
        print "Updating dead directories list..."
        update-dead-dirs
        return
    }

    # Get target path - default to interactive mode when no query
    let target_path = select-dir ($query | default "") --interactive=($interactive or ($query | is-empty))

    # Exit if no path was selected
    if ($target_path | is-empty) { return }

    # Expand the path to full format
    let expanded_path = $target_path | path expand

    # Get directory name for tab naming
    let dir_name = $target_path | path split | last

    zellij-navigate $expanded_path $dir_name --new-tab=$new_tab

    cd $expanded_path
}

# Generate completions for z command from history
export def 'completions-cwds' []: nothing -> record {
    # Using SQL-level filtering for completions as well
    init-dead-cwds-table

    let termsize = term size | get columns | $in - 5
    let max_depth = 6

    # Get open Zellij tabs for marking
    let zellij_tabs = zellij-tab-names

    let variants = open $nu.history-path
    | query db "SELECT h.cwd, MAX(h.start_timestamp) as last_timestamp
               FROM history h
               LEFT JOIN dead_cwds d ON h.cwd = d.path
               WHERE d.path IS NULL
               GROUP BY h.cwd
               ORDER BY MAX(h.id) DESC"
    | where cwd != null
    | update cwd {|i|
        do -i { $i.cwd | path relative-to $nu.home-path }
        | match $in {
            null => $i.cwd
            '' => '~'
            $relative_pwd => ([~ $relative_pwd] | path join)
        }
        | if ($in has ' ') { $'"($in)"' } else { }
    }
    # Filter by depth - skip paths deeper than max_depth
    | where { $in.cwd | path split | length | $in <= $max_depth }
    # Filter by length
    | where ($it.cwd | str length --grapheme-clusters) < $termsize
    | update last_timestamp {|row|
        let timestamp = $row.last_timestamp | into int | $in / 1000 | into int | into datetime -f '%s' | date humanize

        # Check if a Zellij tab exists for this directory
        let dir_name = $row.cwd | path split | last | str replace '"' ''
        let has_tab = $zellij_tabs | any { $in =~ (zellij-tab-pattern $dir_name) }

        if $has_tab { $"⇆ ($timestamp)" } else { $timestamp }
    }
    | rename value description

    {
        options: {
            case_sensitive: false
            completion_algorithm: fuzzy
            positional: false
            sort: false
        }
        completions: $variants
    }
}

# Find and replace text across multiple files by extension
export def 'replace-in-all-files' [
    find: string # Text to search for
    replace: string # Replacement text
    --quiet # Suppress statistics output
    --no-git-check # Skip uncommitted changes check
    --no-rg # Use Nushell instead of ripgrep
    --extensions: list<string> = [nu md py] # File extensions to process
]: nothing -> any {
    let glob = $extensions
    | str join ','
    | str c '**/*.{' $in '}'

    let files_total = glob --no-dir $glob

    let files_found = if (which rg | is-empty) or $no_rg {
        $files_total
        | each {|i|
            open -r $i
            | if ($in | str contains $find) { $i }
        }
        | compact
    } else {
        rg $find --fixed-strings --files-with-matches --glob $glob
        | lines
    }

    let updated = $files_found
    | each {|i|
        if not $no_git_check { git-check-file-clean $i }

        $i | open
        | str replace -a $find $replace
        | str replace -r '\n*$' (char nl)
        | save -f $i
    }
    | length

    if not $quiet {
        let field_name = $'total .($extensions) files'
        # I use record here just for decoration
        {
            $field_name: ($files_total | length)
            'updated': $updated
        }
    }
}

# Error if file has uncommitted git changes
export def git-check-file-clean [
    file: path
]: nothing -> nothing {
    let git_status = git status --porcelain -- $file

    if ($git_status | is-not-empty) {
        error make --unspanned {
            msg: (
                "File has uncommitted changes. Please commit or stash, " +
                "or use `--no-git-check` flag.\n" + $git_status
            )
        }
    }
}

# Insert new lines before the pipe symbol and let/mut
def 'insert-new-lines' []: string -> string {
    let cmd = $in

    ast --flatten $cmd
    | where {|it| $it.shape == shape_pipe or ($it.shape == 'shape_internalcall' and $it.content in [let mut]) }
    | insert new_lines {|i| if $i.shape == shape_pipe { "\n" } else { "\n\n" } }
    | update span { get start }
    | select span new_lines
    | reverse
    | reduce --fold (
        $cmd
        | split chars
    ) {|i| insert $i.span $i.new_lines }
    | str join
}

# Format Nushell code using Topiary formatter
export def 'nu-format' [
    --no-new-lines (-n) # Skip automatic line breaks before pipes
]: [nothing -> nothing string -> string] {
    let input = $in

    let cmd = if $input == null {
        history
        | last 2
        | first
        | get command
    } else { $input }

    $cmd
    | if $no_new_lines { } else {
        insert-new-lines
    }
    | topiary format --language nu
    | if $input == null {
        commandline edit -r $in
        return
    } else { }
}

def 'completions-files-modified' [context: string]: nothing -> record {
    $context
    | split row ' '
    | last
    | if ($in | path type) == 'dir' and $in != '' {
        path join '*' | into glob | ls $in
    } else { ls }
    | sort-by modified -r
    | select name modified
    | update name { if $in has ' ' { $'`($in)`' } else { } }
    | update modified { date humanize }
    | rename value description
    | {
        options: {
            case_sensitive: false
            completion_algorithm: fuzzy
            positional: false
            sort: false
        }
        completions: $in
    }
}

# Resolve symlinks and return target paths, sorted by modification time
export def 'fs' [...files: path@completions-files-modified]: nothing -> any {
    $files
    | uniq
    | each {|i|
        $i
        | if ($in | path type) == symlink {
            ls $i --long
            | update target {|i|
                $i.target
                | if $in starts-with '..' {
                    $i.name
                    | path dirname
                    | path join $i.target
                    | path expand
                    | path relative-to (pwd)
                } else { }
            }
            | get target.0
        } else { }
    }
    | if ($in | length) == 1 {
        first
    } else { }
}

# Retrieve LLM conversation messages by hash suffix
export def 'llm message' [
    ...rest: string@completions-llm-message
]: nothing -> string {
    let dict = llm-open-log

    $rest
    | parse -r '(.{4})$'
    | get capture0
    | each {|i|
        $dict
        | where 'content-hash' == $i
        | last | get content
    }
    | str join "\n\n---\n\n"
}

# Load and deduplicate LLM conversation log
export def 'llm-open-log' []: nothing -> table {
    open ~/short_log.yaml
    | uniq-by content-hash
    | sort-by timestamp -r
}

# Generate completions for llm message command
export def 'completions-llm-message' [
    --first: int = 200
]: nothing -> record {
    llm-open-log
    | each {|i|
        $i.content
        | str replace -ar (char nl) '·' | str substring --grapheme-clusters 0..(
            term size | get columns | $in - 19
        )
        | str c $in $i.content-hash
        | str replace -a '"' "'"
        | to nuon
    }
    | {
        options: {
            case_sensitive: false
            completion_algorithm: fuzzy
            positional: false
            sort: false
        }
        completions: $in
    }
}

# Concatenate rest parameters into a string
@example escape-interpolation { 1 + 1 | str c 'result is ' $in } --result 'result is 2'
export def 'str c' [...rest: any]: nothing -> string { $rest | into string | str join }

# Helper function initially from nupm/utils/dirs.nu
# 
# Try to find the package root directory by looking for nupm.nuon in parent
# directories.
export def find-root [dir?: path]: [nothing -> path nothing -> nothing] {
    let dir2 = $dir | default { pwd }

    let root_candidate = 1..($dir2 | path split | length)
    | reduce -f $dir2 {|_ acc|
        if ($acc | path join '.git' | path exists) {
            $acc
        } else {
            $acc | path dirname
        }
    }

    # We need to do the last check in case the reduce loop ran to the end
    # without finding nupm.nuon
    if ($root_candidate | path join '.git' | path exists) {
        $root_candidate
    } else {
        null
    }
}

# Change directory to git repository root
export def --env cd-root [dir?: path]: [nothing -> nothing] {
    cd (find-root)
}

# Preview text in all available figlet fonts
export def figlet-demo [text: string]: nothing -> record {
    glob /opt/homebrew/Cellar/figlet/2.2.5/share/figlet/fonts/*.flf
    | par-each {|i|
        let i = $i
        | path basename;

        $text
        | figlet -f $i -C utf8
        | wrap $i
    }
    | reduce {|i| merge $i }
}

# Rename Zellij tab, auto-incrementing duplicates
export def rename-tab [name: string = '']: nothing -> nothing {
    let name = if $name == '' { pwd | path basename | str replace -r '^-+' '' } else { $name }

    let name_with_index = zellij action query-tab-names
    | lines
    | where $it =~ $"^($name)\(·|\$)"
    | [($in | length) ($in | parse --regex '(\d+)$' | get -o capture0 | default [0] | into int)]
    | flatten
    | math max
    | if $in > 0 { $'($name)·($in + 1)' } else { $name }

    ^zellij action rename-tab $name_with_index
}
