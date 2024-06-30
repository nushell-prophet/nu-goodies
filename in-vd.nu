use /Users/user/git/nushell-kv/kv.nu

# Open data in VisiData🔥
#
# The suitable format is detected automatically.
# If VisiData produces STDOUT, it will be assigned to $env.vd_temp.n
#
# Examples:
# > history | in-vd
export def main [
    --msgpack (-m)     # force to use msgpack for piping data in-vd
    --csv (-c)      # force to use csv for piping data in-vd
] {
    let $obj = $in

    # > [{a: b, c: d}] | has_hier
    # false
    # > [{a: {c: d}, b: e}] | has_hier
    # true
    def has_hier [] {
        describe
        | find -r '^table(?!.*: (table|record|list))'
        | is-empty
    }

    $obj
    | if ($obj | describe | $in =~ 'FrameCustomValue') {
        polars into-nu
    } else { }
    | if ($csv) or (not ($in | has_hier) and (not $msgpack)) {
        to csv
        | ansi strip
        | vd --save-filetype json --filetype csv -o -
    } else {
        to msgpack
        | vd --save-filetype json --filetype msgpack -o -
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
export def 'history' [ ] {
    where command !~ 'in-vd history'
    | to csv
    | vd --save-filetype csv --filetype csv -o -
    | if ($in == null) { return } else { }
    | from csv
    | get command
    | reverse
    | str join $'(char nl)'
    | str replace -r ';.+?\| in-vd;' ';'
    | commandline edit -r $in
}
