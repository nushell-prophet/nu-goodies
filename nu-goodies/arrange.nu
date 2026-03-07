# Center text within terminal width
export def 'center' [
    --factor: int = 1 # Divide terminal width by this factor
]: string -> string {
    let input = $in | lines | str trim --right

    let max_length = $input | each {ansi strip | str length --grapheme-clusters} | math max
    let term_width = (term size).columns / $factor
    let left_pad = [0 (($term_width - $max_length) // 2)] | math max
    let padding = ('' | fill -c ' ' -w ($left_pad | into int))

    $input
    | each {|line| $padding + $line}
    | str join (char nl)
}

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

# Tile another output to the right of the piped input
#
# > "ab\ncd" | tile-right { "12\n34" }
# ab  12
# cd  34
export def 'tile-right' [
    right: closure # Closure producing the right panel
    --gap: int = 2 # Number of spaces between panels
    --no-truncate (-T) # Don't truncate lines to terminal width
]: any -> string {
    let left = $in | table | into string | lines
    let right_lines = do $right | table | into string | lines

    let left_width = $left | each {ansi strip | str length --grapheme-clusters} | math max
    let left_n = $left | length
    let right_n = $right_lines | length
    let gap_str = ('' | fill -c ' ' -w $gap)

    let width = if $no_truncate { 0 } else { (term size).columns }

    $left
    | append (seq 1 ($right_n - $left_n) | each {''})
    | each {fill -w $left_width}
    | zip ($right_lines | append (seq 1 ($left_n - $right_n) | each {''}))
    | each {|pair| $pair.0 + $gap_str + $pair.1}
    | if not $no_truncate {
        each {ansi strip | str substring 0..<$width --grapheme-clusters}
    } else { }
    | str join (char nl)
}

# Tile another output below the piped input
#
# > "ab" | tile-down { "cd" }
# ab
# cd
export def 'tile-down' [
    bottom: closure # Closure producing the bottom panel
    --gap: int = 0 # Number of blank lines between panels
]: any -> string {
    let separator = 1..($gap + 1) | each {(char nl)} | str join
    ($in | table | into string) + $separator + (do $bottom | table | into string)
}
