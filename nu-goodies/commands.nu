use history.nu [ get-last-commands-from-sql ]
use str.nu [ "str c" ]

# Open table in Less
export def 'L' [
    --abbreviated (-a): int = 1000
    --bat (-b) # Use bat instead of less
]: any -> nothing {
    table -e --abbreviated $abbreviated | into string | if $bat { bat } else { less -R }
}

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
            | into int # Why: 0.114 parse-time typing — `get` rejects `number` as cell-path
        )

    let result = $"($whole_part)($fraction)"
        | fill --character ' ' --width $width
        | if ($foreground == 'default') and ($background == 'default') { } else {
            $"(ansi --escape {fg: ($foreground) bg: ($background)})($in)(ansi reset)"
        }

    if $progress {
        print --no-newline $"($result)\r"
    } else {
        $result
    }
}

# output a command from a pipe where `example` is used, and truncate the output table
#
# > ls nu-goodies | first 3 | reject modified | example
# ╭───────────name───────────┬─type─┬──size──╮
# │ nu-goodies/str.nu        │ file │ 1.4 KB │
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
        | str replace --regex '\| example.*' ''
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
                $"nu -c '($in | str replace --all "'" "'\\''")'"
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

    $table | default $value_to_replace ...($table | columns)
}

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
        | str replace --all --regex '(^|\n)\s+' ''
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

# Hard-link an input table to temp directory (useful for previewing files from large directories in external programs)
#
# > ls | where modified > (date now | $in - 20min) | ln-for-preview
export def --env ln-for-preview [
    --first: int = 500
]: [list -> nothing table -> nothing] {
    let input = $in
    let temp_path = [
        $nu.temp-dir
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

# source ~/git/nu-goodies/nu-goodies/wez-to-ansi.nu
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

# Open Midnight Commander and cd to its exit directory
export def --env mc [
    path1?: path
    path2?: path
]: nothing -> nothing {
    let path = ($nu.temp-dir | path join (random chars))
    let dirs = [$path1 $path2] | compact
    ^mc --nosubshell ...$dirs -P $path
    if ($path | path exists) {
        cd (open --raw $path)
        rm $path
    }
}

# Create directory and cd into it
export def --env md [
    target_dir: string
    -d # Use standard directory
    --dest-dir: path = '~/temp'
]: nothing -> nothing {
    let dir = (
        if $d or ($dest_dir != '~/temp') {
            $dest_dir | path join ($target_dir | str replace --all ' ' '_')
        } else { $target_dir }
        | path expand
    )

    mkdir $dir
    if $env.ZELLIJ? != null {
        ^zellij action rename-tab ($target_dir | path basename)
    }
    cd $dir
}

# Toggle suffix `_back` for a file
export def 'mv1' [
    file: path
]: nothing -> nothing {
    if ($file | str ends-with '_back') {
        mv $file $"($file | str replace --regex '_back$' '')"
    } else {
        mv $file $'($file)_back'
    }
}

# Backup dotfiles and config directories to their git repos
export def 'mygit log' []: nothing -> nothing {
    $nu.home-dir
    | path join '.*'
    | glob $in --depth 1 --no-dir --exclude ['.CFUserTextEncoding']
    | cp --update ...$in '~/.config/dot_home_dir'

    nu ~/.config/nushell/toolkit.nu history backup
}

# history-backup moved to ~/.config/nushell/toolkit.nu

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

# Install nushell or polars from the HEAD or the specified PR
export def 'nu-test install' [
    --nushell # Update nushell only
    --polars # Update polars plugin only
    --nushell-repo-path: path = '~/git/nushell/'
    --cargo-test-path: path = '~/.cargo_test/'
    --plugin-config: path = '~/.test_config/nushell/polars_test.msgpackz'
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

    commandline edit --replace $'^($cargo_test_path | path join bin nu) --plugin-config ($plugin_config)'
}

# Launch the test-installed Nushell binary
export def 'nu-test launch' [
    --no-plugin
]: nothing -> nothing {
    let exec = '~/.cargo_test/' | path join bin nu
    let params = [
        "--execute"
        "$env.PATH = ($env.PATH | prepend '~/.cargo_test/bin/')"
    ]
        | if $no_plugin { } else {
            prepend ['--plugin-config' '~/.test_config/nushell/polars_test.msgpackz']
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
    let nightly_name = ($most_recent_nightly.name | str replace --regex '^Nu-nightly-' '')
    let asset = http get $most_recent_nightly.assets_url
        | where name =~ $arch
        | where name =~ $'($ext)$'
        | get 0

    let filename = (
        $asset.name
        | str replace --regex $ext $'-($nightly_name)($ext)'
        | str replace --regex '^nu-' 'nu-nightly-'
    )

    let destination_file = ($destination_dir | path join $filename)

    print $"Downloading to:(char lf)($destination_file)"

    http get $asset.browser_download_url | save $destination_file
    tar -C $nightly_path -xzf $destination_file
}

# Launch the most recent downloaded nightly Nushell
export def 'launch-downloaded' []: nothing -> nothing {
    let path = glob ($nightly_path | path join *darwin *nu) | sort | last
    commandline edit --replace $path
}

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
        | into string
        | split row '.'
        | get 0
        | str length
        | if $thousands_delim_length > 0 {
            $in + (($in - 1) / 3 | math floor) * $thousands_delim_length
        } else { }
        | append (
            $column_name | str length
            | $in - $decimals - $thousands_delim_length - ($denom | str length --grapheme-clusters)
        )
        | math max

    $input
    | upsert $column_name {
        (
            number-format --denom $denom --decimals $decimals
            --thousands-delim $thousands_delim --integers $integers
            --significant-digits $significant_digits
        )
    }
}

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

    let formatted = $num
        | default $in_num
        | if $significant_digits == 0 { } else {
            significant-digits $significant_digits
        }
        | if $decimals > 0 {
            into string --decimals $decimals
        } else {
            into string
        }
        | split row '.'

    let whole_part = $formatted.0
        | split chars
        | reverse
        | window 3 --stride 3 --remainder
        | each { reverse | str join }
        | reverse
        | str join $thousands_delim
        | if $integers == 0 { } else {
            fill --width $integers --character ' ' --alignment r
        }

    let dec_part = if $decimals == 0 {
        ''
    } else {
        '.' + ($formatted | get 1? | default '0')
    }

    $"(ansi $color)($whole_part)($dec_part)(ansi reset)(ansi green_bold)($denom)(ansi reset)"
}

# Generate 14 lines of spaces (placeholder grid)
export def 'orbita' []: nothing -> list<string> {
    1..14 | each { line ' ' }
}

def line [
    symbol: string
]: nothing -> string {
    1..61 | each { $symbol } | str join
}

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

# https://discord.com/channels/601130461678272522/615253963645911060/1182672999921504336
# by @melmass at discord

# Interactively select columns from a table
export def 'select-i' []: table -> nothing {
    let tgt = $in
    let choices = $tgt
        | columns
        | input list --multi "Pick columns to get: "
        | str join " "

    get-last-commands-from-sql 1
    | str replace 'select-i' $'select ($choices)'
    | commandline edit --replace $in
}

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

# checks for toolkit.nu file in the dir, and puts into commandline `overlay use as tk`
export def --env 'tt' [] {
    if ('toolkit.nu' | path exists) {
        commandline edit "overlay use 'toolkit.nu' --prefix as tk; commandline edit 'tk'"
    } else {
        print 'No toolkit.nu in the current folder. Here are the first 3 files:'
        ls | first 3
    }
}

# Test helper for cd command
export def --env 'testcd' [destination: path]: nothing -> nothing { cd $destination }

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
    let output_file = $nu.temp-dir
        | path join $'(date now | into int).yaml'

    $content | save $output_file

    $output_file
}

# Transcribe audio file to text using whisper.cpp
export def 'transcribe' [file: path]: nothing -> nothing {
    let file = $file
        | if $in =~ '\.wav$' { } else {
            let f = $in + '.wav';
            ffmpeg -i $file -ar 16000 $f;
            $f
        }

    (
        ^~/git/whisper.cpp/build/bin/whisper-cli -f $file
        -m ~/git/whisper.cpp/models/ggml-base.en.bin
        -otxt $'($file).txt' -osrt $'($file).srt' -np
    )
}

# riggrep to output table to capture paths via "[^\\s│]+:\\d+:\\d+" in wezterm
export def 'rgv' --wrapped [...rest] {
    rg --vimgrep ...$rest
    | lines
    | each {
        split row ':' --number 4
        | {path: ($in | first 3 | str join ':') content: ($in | last)}
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
            open --raw $i
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
            | str replace --all $find $replace
            | str replace --regex '\n*$' (char nl)
            | save --force $i
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
        get-last-commands-from-sql 2 | first
    } else { $input }

    $cmd
    | if $no_new_lines { } else {
        insert-new-lines
    }
    | topiary format --language nu
    | if $input == null {
        commandline edit --replace $in
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
    | sort-by modified --reverse
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

# Pipe files into fzf with bat preview in the right pane. Returns the selected path.
# Lines like `file:line` or `file:line:col` (e.g. from `rgv`) highlight that line.
# Binary files show `file --brief` info instead of bat output.
# With --content the preview shows the cell value itself (for long texts),
# and the selection returns the whole row as a record.
export def 'fzf-preview' [
    --column: string # column to take values from (table input); defaults to `name`, `path`, or the first column
    --content # preview cell values themselves instead of files; return the selected row as a record
]: [list<string> -> path list<path> -> path table -> path table -> record nothing -> path] {
    let input = $in | default { ls }

    let values = $input
        | if ($in | describe | str starts-with 'list') { } else {
            if $column != null {
                get $column
            } else if 'name' in ($in | columns) {
                get name
            } else if 'path' in ($in | columns) {
                get path
            } else {
                get ($in | columns | first)
            }
        }

    if $content {
        # Why --read0: NUL-separated items keep their newlines, so {} carries
        # the full value to the preview while --no-multi-line flattens the list
        # display; {n} (input index) maps the selection back to the row.
        # Not a temp json file + jq because: leaks files and adds a dependency.
        let idx = $values
            | each { into string }
            | str join (char --integer 0)
            | fzf --read0 --no-multi-line --preview 'printf %s {}' --preview-window 'right:70%:wrap' --bind 'enter:become(echo {n})'
            | into int

        return ($input | get $idx)
    }

    let preview = 'f={}
l=0
if ! [ -r "$f" ]; then
  rest=$(printf %s "$f" | grep -oE ":[0-9]+(:[0-9]+)?$")
  if [ -n "$rest" ]; then
    base=${f%$rest}
    if [ -r "$base" ]; then
      f=$base
      l=$(printf %s "$rest" | grep -oE "[0-9]+" | head -1)
    fi
  fi
fi
start=1
if [ "$l" -gt 0 ]; then
  start=$((l - ${FZF_PREVIEW_LINES:-40} / 2))
  [ "$start" -lt 1 ] && start=1
fi
case $(file --brief --mime -- "$f") in
  *binary*) file -- "$f" ;;
  *) bat --wrap=auto --terminal-width=${FZF_PREVIEW_COLUMNS:-80} --color=always --pager=never --style=numbers --line-range=$start: --highlight-line=$l -- "$f" ;;
esac'

    $values
    | to text
    | fzf --preview $preview --preview-window 'right:70%'
    | str trim
}

# Helper function initially from nupm/utils/dirs.nu
#
# Try to find the repository root directory by looking for .git in parent
# directories.
export def find-root [dir?: path]: [nothing -> path nothing -> nothing] {
    let dir2 = $dir | default { pwd }

    let root_candidate = 1..($dir2 | path split | length)
        | reduce --fold $dir2 {|_ acc|
            if ($acc | path join '.git' | path exists) {
                $acc
            } else {
                $acc | path dirname
            }
        }

    # We need to do the last check in case the reduce loop ran to the end
    # without finding .git
    if ($root_candidate | path join '.git' | path exists) {
        $root_candidate
    } else {
        null
    }
}

# Change directory to git repository root
export def --env cd-root [dir?: path]: [nothing -> nothing] {
    cd (find-root $dir)
}

# Rename Zellij tab, auto-incrementing duplicates
export def rename-tab [name: string = '']: nothing -> nothing {
    let name = if $name == '' { pwd | path basename | str replace -r '^-+' '' } else { $name }

    let name_with_index = zellij action query-tab-names
        | lines
        | where $it =~ $"^($name)\(·|\$)"
        | [($in | length) ($in | parse --regex '(\d+)$' | get --optional capture0 | default [0] | into int)]
        | flatten
        | math max
        | if $in > 0 { $'($name)·($in + 1)' } else { $name }

    ^zellij action rename-tab $name_with_index
}
