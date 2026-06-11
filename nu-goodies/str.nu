# Repeat a string n times
export def 'str repeat' [
    n: int
]: string -> string {
    let text = $in
    seq 1 $n | each { $text } | str join
}

# Build the separator between input and rest from the convenience flags
def 'build-concatenator' [
    new_line: bool
    tab: bool
    two_space: bool
    space: bool
    extra: string
]: nothing -> string {
    $"(if $new_line { char nl })(if $tab { char tab })(if $two_space { '  ' })(if $space { ' ' })($extra)"
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
    let concatenator = build-concatenator $new_line $tab $2space $space $concatenator

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
    let concatenator = build-concatenator $new_line $tab $2space $space $concatenator

    $"($text | str join $rest_el)($concatenator)($input)"
}

# Escape regex special characters in a string
export def 'escape-regex' []: string -> string {
    str replace --all --regex '([\\.^$*+?{}()\[\]|/])' '\$1'
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
    str replace --all --regex $regex '_'
    | str replace --all --regex '__+' '_'
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
