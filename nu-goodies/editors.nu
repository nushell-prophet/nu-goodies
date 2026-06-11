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

# > [{a: b, c: d}] | has_hier
# false
# > [{a: {c: d}, b: e}] | has_hier
# true
def has_hier []: any -> bool {
    describe | $in !~ '^table(?!.*: (table|record|list))'
}
