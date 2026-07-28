# https://github.com/nushell-prophet/nu-kv
use kv

# Convert data structure to JSON and open it in fx
export def --wrapped in-fx [
    ...rest
]: any -> nothing {
    to json --raw
    | ansi strip
    | ^fx ...$rest
}

# Open data in Helix editor, return edited content to commandline
export def 'in-hx' [
    --path (-p) # Output file path instead of content
]: any -> nothing {
    let input = $in
    let type = $input | describe
    let filename = $nu.temp-dir | path join (date now | format date "%Y%m%d_%H%M%S" | $in + '.nu')

    $input
    | if ($type =~ '(table|record|list)') { to nuon --indent 4 } else { }
    | if ($type =~ '(raw type|string)') { ansi strip } else { }
    | save $filename

    hx $filename

    if $path {
        print $filename
    } else {
        commandline edit --replace $"r######'(open $filename)'######"
    }
}

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
    --no-convert # Send cells as `to csv` renders them, without retyping datetime and filesize
]: any -> any {
    if ($in | describe | $in =~ 'FrameCustomValue') {
        polars into-nu
    } else { }
    | if $csv or not (($in | has_hier) or $json) {
        if $no_convert { } else { vd-friendly }
        | to csv
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

# Convert cells that `to csv` would render for humans into values VisiData can type
#
# Why: `to csv` writes a datetime as `Wed, 1 Jan 2020 10:20:30 +0300 (6 years ago)` —
# the relative-time suffix makes vd's `@` (date) parser fail — and a filesize as the
# rounded `1.2 MB`, which is both unusable for vd's `#` (int) and lossy.
#
# Not per-column because: Nushell has no real column type — a table is a list of records
# and every cell carries its own type. One null makes the column `oneof<datetime, nothing>`,
# rows with different column sets drop the whole table to a bare `table` with no types at
# all, and `update <col>` / `into int <col>` then fail with `Cannot find column`. Per-cell
# costs about 2x (10k rows x 6 cols: +106ms vs +48ms over a 21ms `to csv`) — invisible next
# to starting a TUI.
def vd-friendly []: any -> any {
    let input = $in

    if ($input | describe | $in !~ '^(table|record)') { return $input }

    $input
    | update cells {|value|
        match ($value | describe) {
            'datetime' => ($value | format date '%+') # ISO 8601, what vd's date type parses
            'filesize' => ($value | into int) # bytes
            _ => $value
        }
    }
}

# > [{a: b, c: d}] | has_hier
# false
# > [{a: {c: d}, b: e}] | has_hier
# true
def has_hier []: any -> bool {
    describe | $in !~ '^table(?!.*: (table|record|list))'
}
