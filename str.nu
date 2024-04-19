
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
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # input and rest concatenator
    --rest_el: string = ' ' # rest elements concatenator
] {
    let $input = $in
    let $concatenator = $concatenator
        | if $in != '' {} else {
            if $new_line {(char nl)} else {
                if $tab {(char tab)} else {
                    if $space {' '} else {''}
                }
            }
        }

    $"($input)($concatenator)( $text | str join $rest_el )"
}

export def prepend [
    ...text: string
    --space (-s)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # input and rest concatenator
    --rest_el: string = ' ' # rest elements concatenator
] {
    let $input = $in
    let $concatenator = $concatenator
        | if $in != '' {} else {
            if $new_line {(char nl)} else {
                if $tab {(char tab)} else {
                    if $space {' '} else {''}
                }
            }
        }

    $"( $text | str join $rest_el )($concatenator)($input)"
}

export def indent [] {}

export def dedent [] {}
