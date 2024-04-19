
alias std_append = append
alias std_prepend = prepend

export def repeat [
    $n
] {
    let $text = $in
    seq 1 $n | each {$text} | str join
}

export def append [
    text: string
    --space (-s)
    --new-line (-n)
] {
    $"($in)(if $space {' '})(if $new_line {(char nl)})($text)"
}

export def prepend [
    text: string
    --space (-s)
    --new-line (-n)
] {
    $"($text)(if $space {' '})(if $new_line {(char nl)})($in)"
}

export def indent [] {}

export def dedent [] {}
