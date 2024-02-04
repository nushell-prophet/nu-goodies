export def 'main' [
    filename?
    --dir: string
    --dont_open (-O)
    --up (-u): int = 0
    --all               # Save all history into .nu file
    --directory_hist # get history for a directory instead of session
] {
    let $path = (
        if ($dir == null) {
            [
                (pwd)
                "/Users/user/apps-files/github/nushell_playing/"
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
    )
    let $session = (history session)
    let $hist_raw = (
        history -l
        | if $directory_hist {
            where cwd == (pwd)
        } else {
            where session_id == $session
        })

    let $name = (
        $filename
        | if ($in != null) {} else {
            [
                ($"history($session)"),
                'type your variant'
            ] | input list
            | if ($in == 'type your variant') {
                input 'type your variant: '
            } else {}
        }
    )

    let $filepath = ($path | path join $"($name).nu")

    let $hist = (
        | $hist_raw
        | get command
        | each {|i| $i | str replace -ar $';(char nl)\$.*? in-vd' ''}
    )

    let buffer = (
        if $up > 1 {
            $hist
            | last ($up + 1)
            | drop 1
        } else if $all {
            $hist
            | drop 1
        } else {
            $hist
            | filter {|i| ($i =~ '(^(let|def|export) )|#|\b(save|source|mkdir|dfr to-csv|dfr to-avro|dfr to-jsonl|dfr to-arrow|dfr to-parquet)\b')}
            | append "\n\n"
            | prepend $"#($name)"
        }
    )

    $buffer | save -a $filepath

    if not $dont_open {
        code -n $filepath
    }
}

