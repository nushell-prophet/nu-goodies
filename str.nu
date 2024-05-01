
alias std_append = append
alias std_prepend = prepend

export def repeat [
    $n
] {
    let $text = $in
    seq 1 $n | each {$text} | str join
}

export def append [
    ...text: string
    --space (-s)
    --2space (-2)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # input and rest concatenator
    --rest_el: string = ' ' # rest elements concatenator
] {
    let $input = $in
    let $concatenator = $"(
        if $new_line {(char nl)} )(
        if $tab {(char tab)} )(
        if $2space {'  '} )(
        if $space {' '} )(
        $concatenator
    )"

    $"($input)($concatenator)( $text | str join $rest_el )"
}

export def prepend [
    ...text: string
    --space (-s)
    --2space (-2)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # input and rest concatenator
    --rest_el: string = ' ' # rest elements concatenator
] {
    let $input = $in
    let $concatenator = $"(
        if $new_line {(char nl)} )(
        if $tab {(char tab)} )(
        if $2space {'  '} )(
        if $space {' '} )(
        $concatenator
    )"

    $"( $text | str join $rest_el )($concatenator)($input)"
}

export def indent [] {}

export def dedent [] {}

export def 'escape-regex' [] {
    let $input = $in
    let $regex_special_symbols = [\\, \., \^, "\\$", \*, \+, \?, "\\{", "\\}", "\\(", "\\)", "\\[", "\\]", "\\|", \/]

    $regex_special_symbols
    | str replace '\' ''
    | zip $regex_special_symbols
    | reduce -f $input {|i acc| $acc | str replace -a $i.0 $i.1}
}

export def 'escape-escapes' [] {
    let $input = $in

    help escapes
    | filter {|i| ($i.output | str length) == 1}
    | std_prepend {sequence: '\\' output: '\'}
    | uniq
    | reduce -f $input {|i acc| $acc | str replace -a $i.output $i.sequence}
}
