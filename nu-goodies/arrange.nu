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
