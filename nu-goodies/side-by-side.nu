export def main [
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
