export def main [] {
    let $input = default (
        history | last 2 | first | get command
    )

    let spaces = if ($input =~ '((^|\n)    |\bdef\b)') {'    '} else {''}

    $input
    | str replace -ra ' \|' "\n|"
    | str replace -ra '\n[\n\s]*\|' $"\n($spaces)|"
}
