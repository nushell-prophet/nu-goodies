###file L.nu
# open table in Less
export def 'L' [
    --abbreviated(-a): int = 1000
    --bat(-b) # use bat instead of less
] {
    table -e --abbreviated $abbreviated | into string | if $bat {bat} else {less -R}
}

###file O.nu
def nu-complete-macos-apps [] {
    ls /Applications -s | get name | each {str replace '.app' '' | $'"($in)"' }
}

# Open a file in the specified macOS application or reveal it in Finder (--app flag supports completions)
# > O O.nu --app "Sublime Text"
export def 'O' [
    filepath?: path
    --app (-a): string@'nu-complete-macos-apps' = 'Snagit 2022.app' # app to open at
    --reveal (-r) # reveal app in finder
]: [path -> nothing, nothing -> nothing] {
    if $filepath == null {} else {$filepath}
    | if $reveal {
        ^open -R $in
    } else {
        ^open -a $app $in
    }
}

###file bar.nu
# use std repeat

# construct bars based of a given percentage from a given width (5 is default)
#
# https://github.com/nushell/nu_scripts/blob/bar/sourced/progress_bar/bar.nu
# > bar 0.2
# █
# > bar 0.71
# ███▌
export def 'bar' [
    percentage: float
    --background (-b): string = 'default'
    --foreground (-f): string = 'default'
    --progress (-p) # output the result using 'print -n'
    --width (-w): int = 5
] {
    let blocks = [null "▏" "▎" "▍" "▌" "▋" "▊" "▉" "█"]
    let $whole_part = (($blocks | last) | repeat ($percentage * $width // 1 | into int)) | str join
    let $fraction = (
        $blocks
        | get (
            ($percentage * $width) mod 1
            | $in * ($blocks | length | $in - 1)
            | math round
        )
    )

    let result = (
        $"($whole_part)($fraction)"
        | fill --character $' ' -w $width
        | if ($foreground == 'default') and ($background == 'default') {} else {
            $"(ansi -e {fg: ($foreground), bg: ($background)})($in)(ansi reset)"
        }
    )

    if $progress {
        print -n $"($result)\r"
    } else {
        $result
    }
}

###file bye.nu
# use gradient-screen.nu

export def 'bye' [
    ...strings: string
    --no_date # don't append date
    -n # don't quit
] {
    gradient-screen ...$strings --no_date=$no_date
    if not $n {exit}
}

###file cb.nu
# shortcut for pbpaste and pbcopy. But is it needed?
export def 'cb' [
    --paste
] {
    if $paste or ($in == null) {
        pbpaste
    } else {
        pbcopy
    }
}

###file center.nu
export def 'center' [
    --factor: int = 1
] {
    fill -a center --width ((term size).columns // $factor)
}

###file copy-cmd.nu
# copy this command to clipboard
export def 'copy-cmd' [] {
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
    text?: string # text to format, if omitted stdin will be used
    --color (-c): string@'nu-complete-colors' = 'default' # color to use for the cprint text
    --highlight_color (-H): string@'nu-complete-colors' = 'green_bold' # color to use for highlighting text enclosed in asterisks
    --frame_color (-r): string@'nu-complete-colors' = 'dark_gray' # color to use for frame
    --frame (-f): string = '' # symbol (or a string) to frame a text
    --lines_before (-b): int = 0 # number of new lines before a text
    --lines_after (-a): int = 1 # number of new lines after a text
    --echo (-e) # echo text string instead of printing
    --keep_single_breaks # don't remove single line breaks
    --width (-w): int = 80 # the total width of text to wrap it
    --indent (-i): int = 0 # indent output by number of spaces
    --align: string = 'left' # alignment of text
]: [string -> nothing, nothing -> nothing, nothing -> string, string -> string] {
    let $text = if $text == null {} else {$text}

    let $width_safe = width-safe $width $indent

    $text
    | wrapit $keep_single_breaks $width_safe $indent
    | colorit $highlight_color $color
    | alignit $align $width_safe
    | if $frame != '' {
        frameit $width_safe $frame $frame_color
    } else {}
    | indentit $indent
    | newlineit $lines_before $lines_after
    | if $echo { } else { print -n $in }
}

# I `export` commands here to make them available for testing, yet to be included
# in the same file, so cprint could be easily copied to other projects

export def 'width-safe' [
    $width
    $indent
] {
    term size
    | get columns
    | [$in $width] | math min
    | $in - $indent
    | [$in 1] | math max # term size gives 0 in tests
}

export def 'wrapit' [
    $keep_single_breaks
    $width_safe
    $indent
] {
    str replace -arm '^[\t ]+' ''
    | if $keep_single_breaks { } else { remove_single_nls }
    | str replace -arm '[\t ]+$' ''
    | str replace -arm $"\(.{1,($width_safe)}\)\(\\s|$\)|\(.{1,($width_safe)}\)" "$1$3\n"
    | str replace -r $'\s+$' '' # trailing new line
}

export def 'remove_single_nls' [] {
    str replace -r -a '(\n[\t ]*){2,}' '⏎'
    | str replace -arm '(?<!⏎)\n' ' ' # remove single line breaks used for code formatting
    | str replace -a '⏎' "\n\n"
}

export def 'newlineit' [
    $before
    $after
] {
    $"((char nl) | str repeat $before)($in)((char nl) | str repeat $after)"
}

export def 'frameit' [
    $width_safe
    $frame
    $frame_color
] {
    let $input = $in

    $frame
    | str repeat $width_safe
    | str substring --grapheme-clusters 1..($width_safe) # in case that frame has more than 1 chars
    | $'(ansi $frame_color)($in)(ansi reset)'
    | $in + "\n" + $input + "\n" + $in
}

export def 'colorit' [
    $highlight_color
    $color
] {
    str replace -r -a '\*([^*]+?)\*' $'(ansi reset)(ansi $highlight_color)$1(ansi reset)(ansi $color)'
    | $'(ansi $color)($in)(ansi reset)'
}

export def 'alignit' [
    $alignment: string
    $width_safe
] {
    lines
    | fill --alignment $alignment --width $width_safe
    | str join (char nl)
}

export def 'indentit' [
    $indent
] {
    str replace -arm '^' (char sp | str repeat $indent)
}

def 'nu-complete-colors' [] {
    ansi --list | take until {|it| $it.name == reset} | get name
}

###file dfr enumerate.nu
export def 'dfr enumerate' [
    n: int = 3
] {
    dfr first $n
    | dfr into-nu
    | enumerate
}

###file example.nu
# output a command from a pipe where `example` used, and truncate the output table
#
# > ls nu-goodies | first 3 | reject modified | example
# ╭───────────name───────────┬─type─┬──size──╮
# │ nu-goodies/str.nu        │ file │ 1.4 KB │
# │ nu-goodies/cb.nu         │ file │  170 B │
# │ nu-goodies/abbreviate.nu │ file │  898 B │
# ╰───────────name───────────┴─type─┴──size──╯
export def 'example' [
    --dont_copy (-C)
    --dont_comment (-H)
    --indentation_spaces (-i): int = 1
    --abbreviated: int = 10
] {
    let $input = table --abbreviated $abbreviated
        | if $dont_comment {} else {ansi strip}

    history
    | last
    | get command
    | str replace -r '\| example.*' ''
    | if $dont_comment {
        nu-highlight # for making screnshots
    } else {}
    | $'#(char nl)> ($in)(char nl)($input)'
    | if $dont_comment {} else {
        lines
        | each {|i| $'#(seq 1 $indentation_spaces | each {" "} | str join '')($i)'}
        | str join (char nl)
    }
    | if $dont_copy {} else {
        let $i = $in
        $i | pbcopy
        $i
    }
}

###file fill non-exist.nu
# fill missing columns for each row
#
# this is how empty columns are present
# > [{a: 1} {b: 2}] | to nuon
# [{a: 1}, {b: 2}]
#
# > [{a: 1} {b: 2}] | fill non-exist | to nuon
# [{a: 1, b: ""}, {b: 2, a: ""}]
export def 'fill non-exist' [
    value_to_replace: any = ''
] {
    let $table = $in

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

# format `debug profile` output
#
# > debug profile {pin-text cyber} --max-depth 7 --spans | format profile | null
export def 'format profile' [] {
    skip
    | update depth {|i| $i.depth - 1}
    | normalize duration_ms
    | update duration_ms_norm {bar $in --width 16}
    | insert fullspan {|i| view span $i.span.start $i.span.end
        | str replace -ar '(^|\n)\s+' ''
        | str substring 0..((term size).columns - 40 - ($i.depth * 2))}
    | insert hier {|i| seq 1 $i.depth
        | each {'│ '}
        | str join
        | $in + "├─" + ($i.fullspan)}
    | sort-by id
    | reject span source fullspan parent_id id depth
}

###file gradient-screen.nu
# fill screen with repeated texts from arguments or $env.gradient-screen.texts with random color gradient
export def --env gradient-screen [
    ...strings: string
    --no_date # don't append date
    --echo
    --rows: int
] {
    let $strings = $strings
        | if $in == [] {
            $env.gradient-screen?.texts?
            | default [
                '<nushell<is<awesome<'
                '<wezterm<is<awesome<'
                'and<you<are<awesome<'
            ]
        } else {}

    let $screen_size = term size
        | if $rows == null {values} else {
            $in.columns * $rows
        }
        | math product


    let $1_list = $strings.0 | split chars
    let $1_len = $1_list | length
    let $date_text = date now | format date "%Y%m%d_%H%M%S"

    let colors = rand_hex_col2

    $env.gradient-screen-last-colors = $colors

    let $other_strings = $strings
        | skip
        | each {|i|
            $'($i)($1_list | last ($1_len - ($i | str length) mod $1_len) | str join)'
        }
        | append ''

    let $other_len = $other_strings
        | str length
        | math sum

    let $n_chunks = ($screen_size - $other_len) // $1_len

    let $base = seq 0 $n_chunks
        | each {$strings.0}

    $other_strings
    | reduce -f $base {|i acc|
        $acc
        | insert (random int 3..$n_chunks) $i
    }
    | str join
    | split chars --grapheme-clusters
    | first $screen_size
    | if $no_date {} else {
        drop ($date_text | str length)
        | append ($date_text | split chars)
    }
    | window $1_len --stride $1_len --remainder
    | each {str join | ansi gradient --fgstart $colors.0 --fgend $colors.1}
    | str join
    | if $echo {} else {
        print; sleep 2sec;
    }
}

def generate_colors [] {1..3 | each {(random int 0..255)}}

def make_hex [] {each {into binary --compact  | encode hex} | prepend '0x' | str join}

def check_colors [c0 c1 --threshold = 250] {
    ($c0 | zip $c1 | each {|i| ($i.0 - $i.1) ** 2} | math sum | math sqrt) > $threshold
}

def rand_hex_col2 [] {
    mut color0 = []
    mut color1 = []

    for pair in 1..30 {
        $color0 = (generate_colors)
        $color1 = (generate_colors)
        if (check_colors $color0 $color1) {
            break
        }
    }

    if not (check_colors $color0 $color1) {
        let rand = random int 100..180
        $color1 = ($color0 | each {($in + $rand) mod 255})
    }

    [$color0 $color1] | each {make_hex}
}

###file hist.nu
alias core_hist = history
# use in-vd.nu

# Filter history with regex and convenient flags, add useful columns
export def 'hist' [
    ...query: string # a regex to search for
    --entries: int = 5000 # a number of last entries to work with
    --all (-a) # return all the history
    --session (-s) # show only entries from the current session
    --folder # show only entries from the current folder
    --last_x: duration # duration for the period to check commands
    --not_in_vd (-V) # disable opening command in visidata
] {
    if $in != null {} else {
        core_hist -l
        | if $session { where session_id == (history session) } else {}
        | if $folder { where cwd == (pwd) } else {}
        | if ($entries == 0) or $all {} else { last $entries }
        | where command !~ '^hist '
        | where exit_status == 0
    }
    | if $last_x != null {
        where start_timestamp > ((date now) - $last_x | format date '%F %X')
    } else {}
    | if $query == [] {} else {
        let $inp = $in

        $query
        | reduce -f $inp {|it acc|
            $acc | filter {|i| $i.command =~ $it}
        }
    }
    | if 'duration_s' in ...($in | columns) {} else {
        insert duration_s {|i| $i.duration | into int | $in / (10 ** 9)}
        | reject -i item_id duration hostname
        | move start_timestamp --after command
        | upsert pipes {|i| ast --flatten $i.command | where shape == shape_pipe | length}
    }
    | if $not_in_vd {} else { in-vd history }
}

###file hs.nu
# Save significant or all current session history entries into a .nu file. If the .nu file already exists, data will be appended.
export def 'hs' [
    filename?
    --dir: string # where to save history file
    --dont_open (-O) # don't open the save history file in editor
    --up (-u): int = 0 # set number of last events to save
    --all # Save all history into .nu file
    --directory_hist # get history for a directory instead of session
] {
    let $path = if $dir == null {
            [
                (pwd)
                "/Users/user/git/nushell_playing/"
                'type your variant'
                'use gum'
            ]
            | input list 'choose directory'
            | if ($in | path exists) {} else {
                match $in {
                    'type your variant' => {input 'type your variant'},
                    'use gum' => {
                        gum file --directory (pwd)
                        | str trim -c (char nl)
                        | if ($in | path type) == 'file' {
                            path basename
                        } else {}
                    }
                }
            }
            | if ($in | path exists) {} else {
                error make {msg: $"the path ($in) doesn't exist"}
            }
        } else {$dir}
        | path expand

    let $session = history session
    let $hist_raw = history -l
        | if $directory_hist {
            where cwd == (pwd)
        } else {
            where session_id == $session
        }

    let $name = $filename
        | if ($in != null) {} else {
            [
                ($"history($session)"),
                'type your variant'
            ] | input list
            | if ($in == 'type your variant') {
                input 'type your variant: '
            } else {}
        }

    let $filepath = $path
        | path join $"($name).nu"

    let $hist = $hist_raw
        | get command
        | each {|i| $i | str replace -ar $';(char nl)\$.*? in-vd' ''}

    let buffer = if $up > 1 {
            $hist
            | last ($up + 1)
            | drop 1
        } else if $all {
            $hist
            | drop 1
        } else {
            $hist
            | filter {|i| $i =~ '(^(let|def|export) )|#|\b(save|source|mkdir|polars to-csv|polars to-avro|polars to-jsonl|polars to-arrow|polars to-parquet)\b'}
            | append "\n\n"
            | prepend $"#($name)"
        }

    $buffer | save -a $filepath

    if not $dont_open {
        code -n $filepath
    }
}

###file in-fx.nu
# convert datastructure to json and open it in fx
export def --wrapped in-fx [
    ...rest
] {
    to json -r
    | ansi strip
    | ^fx ...$rest
}

###file in-hx.nu
# open piped-in results in hx, output back the saved file
export def 'in-hx' [
    --path (-p) # output path of the file
] {
    let $input = $in
    let $type = $input | describe
    let $filename = $nu.temp-path | path join (date now | format date "%Y%m%d_%H%M%S" | $in + '.nu')

    $input
    | if ($type =~ '(table|record|list)') { to nuon } else {}
    | if ($type =~ '(raw type|string)') { ansi strip } else {}
    | save $filename

    hx $filename

    if $path {
        print $path
    } else {
        commandline edit -r (open $filename)
    }
}

###file in-vd.nu
# https://github.com/nushell-prophet/nu-kv
use /Users/user/git/nushell-kv/kv/

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
    --json (-j) # force to use msgpack for piping data in-vd
    --csv (-c) # force to use csv for piping data in-vd
] {
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
    | from json  # vd will output the final sheet `ctrl + shift + q`
    | if ($in != null) {
        if ($in | columns) == [''] {
            get ''
        } else {}
        | kv set vd
    }
}

# Open nushell commands history in visidata
export def 'in-vd history' [ ] {
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
def has_hier [] {
    describe
    | find -r '^table(?!.*: (table|record|list))'
    | is-empty
}

###file ln-for-preview.nu
# hardlink an input table to temp directory (useful for previewing files from large directories in external programs)
#
# > ls | where modified > (date now | $in - 20min) | ln-for-preview
export def --env ln-for-preview [
    --first: int = 500
]: [list -> nothing, table -> nothing] {
    let $input = $in
    let $temp_path = [
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
            | each {ln $in $temp_path}
        } else {
            error make {msg: 'no name column in input table'}
        }
    } else if ($in | describe | $in =~ '^list') {
        each {ln $in $temp_path}
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
# open midnight commander, cd to the last folder
export def --env mc [
    path1?: path
    path2?: path
] {
    let $path = ($nu.temp-path | path join (random chars))
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
# makedir and cd into it
export def --env md [
    target_dir
    -d # use standard directory
    --dest_dir: path = '/Users/user/temp'
] {
    let $dir = (
        if $d or ($dest_dir != '/Users/user/temp') {
            $dest_dir | path join ($target_dir | str replace -a ' ' '_')
        } else {$target_dir}
        | path expand
    )

    mkdir $dir
    if $env.ZELLIJ? != null {
        ^zellij action rename-tab ($target_dir | path basename)
    }
    cd $dir
}


###file mv1.nu
# toggle suffix `_back` for a file
export def 'mv1' [
    file: path
] {
    if ($file | str ends-with '_back') {
        mv $file $"($file | str replace -r '_back$' '')"
    } else {
        mv $file $'($file)_back'
    }
}

###file mygit log.nu
# commit current version of dot files and apps settings
export def 'mygit log' [
    --message (-m): string
] {
    let $message = $message
        | default (date now | format date "%Y-%m-%d")

    let $dot_dir = '~/.config/dot_home_dir'
        | path expand

    $nu.home-path
    | path join '.*'
    | glob $in -d 1 --no-dir --exclude [ '.CFUserTextEncoding' ]
    | par-each {|i| cp --update $i $dot_dir}

    backup-history

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

export def 'backup-history' [] {
    let hist_backups_dir = '~/.config/nushell/history-backups/'
        | path expand

    let date_uniq = date now
        | format date '%F_%T_%f'
        | str replace -ra '([^\d_])' ''

    let temp_hist_folder = $hist_backups_dir
        | path join $date_uniq

    let $history_back_file = $temp_hist_folder
        | path join 'history.sqlite3'

    mkdir $temp_hist_folder

    # sqlite3 $nu.history-path 'PRAGMA wal_checkpoint(FULL);'
    sqlite3 $nu.history-path $'.backup ($history_back_file)'

    sqlite3 $history_back_file ".dump history"
    | save ($hist_backups_dir | path join 'history_back.sql') -f
}

###file normalize.nu
# normalize values in given columns
#
# > [[a b]; [1 2] [3 4] [a null]] | normalize a b
# ╭─a─┬─b─┬a_norm┬b_norm╮
# │ 1 │ 2 │ 0.33 │ 0.50 │
# │ 3 │ 4 │    1 │    1 │
# │ a │   │ a    │      │
# ╰───┴───┴──────┴──────╯
export def 'normalize' [
    ...column_names
    --suffix = '_norm'
] {
    mut $table = ($in)

    for column in $column_names {
        let $max_value = $table
            | get $column
            | where ($it | describe | $in in ['int' 'float'])
            | math max

        $table = (
            $table
            | upsert $'($column)($suffix)' {
                |i| $i
                | get $column
                | if ($in | describe | $in in ['int' 'float']) {
                    $in / $max_value
                } else {}
            }
        )
    }

    $table
}

###file nu-test.nu
# install nushell or polars from the HEAD or the specified PR
export def 'nu-test install' [
    --nushell # update nushell only
    --polars # update polars plugin only
    --nushell-repo-path: path = '/Users/user/git/nushell/'
    --cargo-test-path: path = '/Users/user/.cargo_test/'
    --plugin-config: path = '/Users/user/.test_config/nushell/polars_test.msgpackz'
    --pr: string # a pr to checkout like ayax79:polars_pivot
] {
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

export def 'nu-test launch' [
    --no-plugin
] {
    let $exec = '/Users/user/.cargo_test/' | path join bin nu
    let $params = [
            "--execute" "$env.PATH = ($env.PATH | prepend '/Users/user/.cargo_test/bin/')"
        ]
        | if $no_plugin {} else {
           prepend ['--plugin-config' '/Users/user/.test_config/nushell/polars_test.msgpackz']
        }

    ^$exec ...$params
}

const nightly_path = '~/temp/nu-nightly' | path expand

export def --env download-nushell-nightly [
  --arch (-a): string = 'aarch64-apple-darwin'    # archicture as specified in nushell/nightly repo
  --ext (-e): string = '.tar.gz'                      # extension, including the leading dot (e.g. '.tar.gz')
  --destination_dir (-d): directory = $nightly_path   # destination directory in which to save the download
] {
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

export def 'launch-downloaded' [] {
  let path = glob ($nightly_path | path join *darwin *nu) | sort | last
  commandline edit -r $path
}

###file number-col-format.nu
# use number-format.nu

# Format number column in a table using number-format
#
# > [[a]; [123456.678] [2345.8900]] | number-col-format a --denom wt --decimals 2 --significant_digits 3
# ╭──────a───────╮
# │ 123_000.00wt │
# │   2_340.00wt │
# ╰──────────────╯
export def 'number-col-format' [
    column_name: string # A column name to format
    --thousands_delim (-t) = '_' # Thousands delimiter: number-format 1000 -t ': 1'000
    --decimals (-d) = 0 # Number of digits after decimal delimiter: number-format 1000.1234 -d 2: 1000.12
    --denom (-D) = '' # Denom `--denom "Wt": number-format 1000 --denom 'Wt': 1000Wt
    --significant_digits: int = 0 # The number of first digits to display, others will become 0
] {
    let $input = $in

    if $column_name not-in ($input | columns) {
        error make {'msg': $'There is no ($column_name) in columns'}
    }

    let $thousands_delim_length = $thousands_delim | str length --grapheme-clusters

    let $integers = $input
        | get $column_name
        | math max
        | split row '.'
        | get 0
        | str length
        | if $thousands_delim_length > 0 {
                $in * ((3 + $thousands_delim_length) / 3 - 0.001) | math floor
        } else {}
        | append (
            $column_name | str length
            | $in - $decimals - $thousands_delim_length - ($denom | str length --grapheme-clusters)
        )
        | math max


    $input
    | upsert $column_name {|i|
        ( number-format ($i | get $column_name)
            --denom $denom --decimals $decimals
            --thousands_delim $thousands_delim --integers $integers
            --significant_digits $significant_digits)
    }
}

###file number-format.nu
# use significant-digits.nu

# Format big numbers nicely
#
# > number-format 1000 --thousands_delim "'"
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
    num? # Number to format
    --thousands_delim (-t): string = '_' # Thousands delimiter
    --integers (-i): int = 0 # Length of padding whole-part digits
    --significant_digits: int = 0 # The number of first digits to display, others will become 0
    --decimals (-d): int = 0 # Number of digits after decimal delimiter
    --denom (-D): string = '' # Denom
    --color: string = 'green'
] {
    let $in_num = $in

    let parts = $num
        | default $in_num
        | if $significant_digits == 0 {} else {
            significant-digits $significant_digits
        }
        | into string
        | split chars
        | split list '.'

    let $whole_part = $parts.0
        | reverse
        | window 3 -s 3 --remainder
        | each {reverse | str join}
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
export def 'orbita' [] {
    1..14 | each {line ' '}
}

def line [
    symbol: string
] {
    1..61 | each {$symbol} | str join
}

###file print-and-pass.nu
# An alternative to `inspect` that doesn't break debugging output
export def 'print-and-pass' [
    callback?: closure
] {
    let $input = $in

    if $callback == null {
        print $input
    } else {
        print (do $callback $input)
    }

    $input
}

###file ramdisk-create.nu
# Create ramdisk in MacOS
export def 'ramdisk-create' [
    size: filesize = 4194304kb
] {
    let $vol = (hdiutil attach -nobrowse -nomount $'ram://($size | into int | $in * 1.024 / 1000 * 2)' | str trim);
    sleep 2sec
    (^diskutil erasevolume HFS+ RAMDisk $vol)
    cd /Volumes/RAMDisk
}

###file select-i.nu
# https://discord.com/channels/601130461678272522/615253963645911060/1182672999921504336
# by @melmass at discord

# interactively select columns from a table
export def 'select-i' [] {
    let tgt = $in
    let $choices = $tgt
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
export def 'side-by-side' [
    r
    --delimiter: string = ' ' # delimiter between left and right
    --collapse # use collapsed table representation
    --l_header: string
    --r_header: string
] {
    mut $l = $in | if $collapse {table} else {table -e} | into string | lines
    mut $r = $r | if $collapse {table} else {table -e} | into string | lines

    if $l == $r {
        print 'equal!'
    }

    if $l_header != null or $r_header != null {
        $l = ([$" (ansi yellow)($l_header)(ansi reset) "] | append $l)
        $r = ([$" (ansi yellow)($r_header)(ansi reset) "] | append $r)
    }

    let $l_strip = $l | ansi strip
    let $l_str_len_max = $l_strip | str length --grapheme-clusters | math max
    let $l_n_lines = $l_strip | length

    let $r_strip = $r | ansi strip
    let $r_str_len_max = $r_strip | str length --grapheme-clusters | math max
    let $r_n_lines = $r_strip | length

    let $res = $l | append (
            seq 1 ($r_n_lines - $l_n_lines)
            | each { seq 1 $l_str_len_max | each {' '} | str join }
        )
        | each {fill --width $l_str_len_max}
        | zip (
            $r | append (
                seq 1 ($l_n_lines - $r_n_lines)
                | each {''}
            )
        )
        | each {|i| $i.0 + $delimiter + $i.1}
        | str join (char nl)

    let $width = term size | get columns

    $res
    | if ($r_str_len_max + $l_str_len_max + ($delimiter | str length)) > $width {
        lines
        | ansi strip
        | str substring 0..$width --grapheme-clusters
        | str join (char nl)
    } else {}
}

###file significant-digits.nu
# the samve version as https://github.com/nushell/nu_scripts/blob/significant-digits/stdlib-candidate/std-rfc/math/mod.nu

# replace all insignificant digits with 0
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
]: [int -> int, float -> float, duration -> duration] {
    let $input = $in
    let $type = $input | describe

    let $num = match $type {
        'duration' => {$input | into int}
        _ => {$input}
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
        'duration' => {$res | into duration}
        'int' => {$res | into int}
        _ => {$res}
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

export def 'str repeat' [
    $n
] {
    let $text = $in
    seq 1 $n | each {$text} | str join
}

export def 'str append' [
    ...text: string
    --space (-s)
    --2space (-2)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # input and rest concatenator
    --rest_el: string = ' ' # rest elements concatenator
] {
    let $input = $in
    let $concatenator = $"(
        if $new_line {(char nl)} )(
        if $tab {(char tab)} )(
        if $2space {'  '} )(
        if $space {' '} )(
        $concatenator
    )"

    $"($input)($concatenator)( $text | str join $rest_el )"
}

export def 'str prepend' [
    ...text: string
    --space (-s)
    --2space (-2)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # input and rest concatenator
    --rest_el: string = ' ' # rest elements concatenator
] {
    let $input = $in
    let $concatenator = $"(
        if $new_line {(char nl)} )(
        if $tab {(char tab)} )(
        if $2space {'  '} )(
        if $space {' '} )(
        $concatenator
    )"

    $"( $text | str join $rest_el )($concatenator)($input)"
}

export def 'indent' [] {}

export def 'dedent' [] {}

export def 'escape-regex' [] {
    str replace --all --regex '(\\|\.|\^|\$|\*|\+|\?|\{|\}|\(|\)|\[|\]|\||\/)' '\$1'
}

export def 'escape-escapes' [] {
    str replace --all --regex '(\\|\"|\/|\(|\)|\{|\}|\$|\^|\#|\||\~)' '\$1'
}

###file testcd.nu
export def 'testcd' --env [destination] {cd $destination}

export def 'to-safe-filename' [
    --prefix: string = ''
    --suffix: string = ''
    --regex: string = '[^A-Za-z0-9_А-Яа-я+]' # symbols to keep
    --date
]: string -> string {
    str replace -ra $regex '_'
    | str replace -ra '__+' '_'
    | if $date {
        $'(now-fn)+($in | str substring ..30)' # make string uniq
    } else if (($in | str length) > 30) {
        $'($in | str substring ..30)($in | hash sha256 | str substring ..10)' # make string uniq
    } else {}
    | $'($prefix)($in)($suffix)'
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
    content?     # Commands used to generate the content of the file.
] {
    let content = if $content == null {} else {$content}
    let output_file = $nu.temp-path
        | path join $'(date now | into int).yaml'

    $content | save $output_file

    $output_file
}

###file transcribe.nu
export def 'transcribe' [file: path] {
    let $file = $file
        | if $in =~ '\.wav$' {} else {
            let $f = $in + '.wav';
            ffmpeg -i $file -ar 16000 $f;
            $f
        }

    (^/Users/user/git/whisper.cpp/transcribe -f $file
        -m /Users/user/git/whisper.cpp/models/ggml-base.en.bin
        -otxt $'($file).txt' -osrt $'($file).srt' -np )
}

###file wez-to-ansi.nu
export def 'wez-to-ansi' [
    $n_last_commands: int = 2 # Number of recent commands (and outputs) to capture.
    --regex: string = '^>' # Regex to separate prompts from outputs. Default is ''.
    --lines_before_top_of_term: int = 100 # Lines from top of scrollback in Wezterm to capture.
    --min_term_width: int = 0
] {

    # let $regex = '^' + (ansi green_italic) + '>'

    ^wezterm cli get-text --escapes --start-line ($lines_before_top_of_term * -1)
    | str replace -a $"\n(ansi blue_bold)> " "\n>"
    | str replace -ra '(\r|\n)+$' ''
    | inspect
    | lines
    | skip until {|i| $i =~ $regex}
    | split list --regex $regex
    | drop
    | last $n_last_commands
    | flatten
    | if $min_term_width == 0 { } else {
        prepend (seq 1 $min_term_width | each {' '} | str join)
    }
    | str join (char nl)
}

###file wez-to-gif.nu
#wez-to-gif
export def 'wez-to-gif' [
    command: string = ''
    --filename: path
    --font-family: string = "Iosevka Extended"
    --font-size: int = 20
    --ascinema # copy ascinema here too
] {
    let $wezrec = ^wezterm record --cwd (pwd) -- $nu.current-exe --execute $'source $nu.env-path; clear; ($command)'
        | complete
        | get stderr
        | str replace -r '.*\n.*\/var' '/var'
        | str trim -c (char nl)

    let target_folder = '/Users/user/temp/wezterm-asciinemas'
        | path join $'gif_(pwd | path split | last)'
        | $'($in)(mkdir $in)'


    let $gif_name = $target_folder
        | path join ($filename
            | default $'_wez_gif_(date now | format date `%s`).gif')

    print $wezrec

    cp $wezrec $target_folder

    ^agg --font-family $font_family --font-size $font_size -v $wezrec $gif_name
    print ''

    ^open -R $gif_name # reveal in finder
}

###file wez-to-png.nu
# capture wezterm scrollback, split by prompts, output chosen to an image file
# uses nu_plugin_image
# https://wezfurlong.org/wezterm/index.html
# https://github.com/FMotalleb/nu_plugin_image/

# use wez-to-ansi.nu

# capture wezterm scrollback, split by prompts, output chosen ones to an image file
export def 'wez-to-png' [
    $n_last_commands: int = 2 # Number of recent commands (and outputs) to capture.
    --output_path: path = '' # Path for saving output images.
] {
    let $output_path = $output_path
        | if $in != '' {} else {
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

def now-fn []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}

def last-commands [
    $n_last_commands
]: nothing -> string {
    history
    | last ($n_last_commands + 1)
    | drop # drop the last command to initiate image capture
    | get command
    | str trim
    | str join '_'
}


###file z.nu
export def --env z [
    ...rest: string
    --interactive(-i)
    --new-tab(-n)
]: nothing -> nothing {
    let $query = $rest | str join ' '

    let $cwds = open $nu.history-path
        | query db "select distinct(cwd) from history order by id desc"
        | get cwd
        | to text

    let $interactive_query = {
        $cwds | fzf --scheme=path -q $query
    }


    let $path = if $interactive {
            do $interactive_query
        } else {
            $cwds
            | fzf --scheme=path -f $query
            | lines
            | get 0?
            | if $in == null { # nothing has been found - launch interactive
                do $interactive_query
            } else {}
        }
        | if ($in | is-empty) { return } else { path expand }

    if ($env.ZELLIJ? | is-not-empty) {
        if $new_tab {
            zellij action new-tab --layout default --cwd $path --name $query
            return
        } else {
            zellij action rename-tab $query
        }
    }

    cd $path
}

export def 'replace-in-all-files' [
    $find
    $replace
    --quiet # don't outuput stats
    --no-git-check
] {
    let $files = glob --no-dir **/*{nu,md}

    let $files_found = $files
        | each {|i|
            open $i
            | if ($in | str contains $find) {$i}
        }
        | compact

    mut $rec = {
        'files nu and md files total count': ($files | length)
        'updated': 0
    }

    for $i in $files_found {
        if not $no_git_check {check-clean-working-tree $i}

        $i | open
        | str replace -a $find $replace
        | str replace -r '\n*$' (char nl)
        | save -f $i

        $rec.updated += 1
    }

    if not $quiet {$rec}
}

export def 'check-clean-working-tree' [
    $module_path: path
] {
    cd ( $module_path | path dirname )

    let git_status = git status --short

    $git_status
    | lines
    | parse '{s} {m} {f}'
    | where f =~ $'( $module_path | path basename )$'
    | is-not-empty
    | if $in {
        error make --unspanned {
            msg: ( "Working tree isn't empty. Please commit or stash changed files, " +
                    "or use `--no-git-check` flag. Uncommited files:\n" + $git_status )
        }
    }
}
