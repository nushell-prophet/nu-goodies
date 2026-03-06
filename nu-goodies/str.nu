alias std_append = append
alias std_prepend = prepend

# Repeat a string n times
export def 'str repeat' [
    n: int
]: string -> string {
    let text = $in
    seq 1 $n | each { $text } | str join
}

# Append strings with optional separators
export def 'str append' [
    ...text: string
    --space (-s)
    --2space (-2)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # Input and rest concatenator
    --rest-el: string = ' ' # Rest elements concatenator
]: string -> string {
    let input = $in
    let concatenator = $"(
        if $new_line { (char nl) }
    )(
        if $tab { (char tab) }
    )(
        if $2space { '  ' }
    )(
        if $space { ' ' }
    )(
        $concatenator
    )"

    $"($input)($concatenator)($text | str join $rest_el)"
}

# Prepend strings with optional separators
export def 'str prepend' [
    ...text: string
    --space (-s)
    --2space (-2)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # Input and rest concatenator
    --rest-el: string = ' ' # Rest elements concatenator
]: string -> string {
    let input = $in
    let concatenator = $"(
        if $new_line { (char nl) }
    )(
        if $tab { (char tab) }
    )(
        if $2space { '  ' }
    )(
        if $space { ' ' }
    )(
        $concatenator
    )"

    $"($text | str join $rest_el)($concatenator)($input)"
}

# Add indentation to text (not implemented)
export def 'indent' []: string -> string { $in }

# Remove indentation from text (not implemented)
export def 'dedent' []: string -> string { $in }

# Escape regex special characters in a string
export def 'escape-regex' []: string -> string {
    let input = $in
    let regex = '\.^$*+?{}()[]|/' | split chars | each { $'\($in)' } | str join '|' | $"\(($in))"

    $input | str replace --all --regex $regex '\$1'
}

# Escape Nushell special characters for string interpolation
export def 'escape-nushell-escapes' []: string -> string {
    str replace --all --regex '(\\|\"|\/|\(|\)|\{|\}|\$|\^|\#|\||\~)' '\$1'
}

def 'now-fn' []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}

# Convert string to filesystem-safe filename
export def 'to-safe-filename' [
    --prefix: string = '' # Prepend to filename
    --suffix: string = '' # Append to filename
    --regex: string = '[^A-Za-z0-9_А-Яа-я+]' # Characters to replace
    --date # Prepend timestamp for uniqueness
]: string -> string {
    str replace -ra $regex '_'
    | str replace -ra '__+' '_'
    | if $date {
        $'(now-fn)+($in | str substring ..30)' # make string uniq
    } else if (($in | str length) > 30) {
        $'($in | str substring ..30)($in | hash sha256 | str substring ..10)' # make string uniq
    } else { }
    | str c $prefix $in $suffix
}

# Concatenate rest parameters into a string
@example escape-interpolation { 1 + 1 | str c 'result is ' $in } --result 'result is 2'
export def 'str c' [...rest: any]: nothing -> string { $rest | into string | str join }
