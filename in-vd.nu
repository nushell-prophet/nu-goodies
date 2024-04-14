use /Users/user/git/nushell-kv/kv.nu

# Open data in VisiData🔥
#
# The suitable format is detected automatically.
# If VisiData produces STDOUT, it will be assigned to $env.vd_temp.n
#
# Examples:
# > history | in-vd
export def main [
    --dont_strip_ansi_codes (-S) # ansi codes are stripped by default, this option disables stripping ansi codes.
    --json (-j)     # force to use json for piping data in-vd
    --csv (-c)      # force to use csv for piping data in-vd
] {
    let $obj = $in

    # > [{a: b, c: d}] | is_flat
    # true
    # > [{a: {c: d}, b: e}] | is_flat
    # false
    def is_flat [] {
        $in
        | describe
        | find -r '^table(?!.*: (table|record|list))'
        | is-empty
        | not $in
    }

    $obj
    | if ($obj | describe | $in == 'dataframe') {
        dfr into-nu
        | reject index
    } else { }
    | if ($csv) or (($in | is_flat) and (not $json)) {
        to csv
        | if not $dont_strip_ansi_codes {
            ansi strip
        } else { }
        | vd --save-filetype json --filetype csv -o -
    } else {
        to json -r
        | if not $dont_strip_ansi_codes {
            ansi strip
        } else { }
        | vd --save-filetype json --filetype json -o -
    }
    | from json  # vd will output the final sheet `ctrl + shift + q`
    | if ($in != null) {
        kv set vd
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
    | str join $';(char nl)'
    | str replace -r ';.+?\| in-vd;' ';'
    | commandline edit -r $in
}
