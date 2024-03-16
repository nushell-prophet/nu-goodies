export def main [
    $n_commands: int = 1
    --lines_before_top: int = 100
    --regex: string = '' # some regex to split prompts with results from each other
    --min_term_width: int = 120
    --date # make images uniq by prepending date
] {
    let $filename = (
        last-commands $n_commands
        | to-safe-filename --suffix '.png' --date=$date
    )

    ^wezterm cli get-text --escapes --start-line ($lines_before_top * -1)
    | str replace -ra '(\r|\n)+$' ''
    | lines
    | skip until {|i| $i =~ $regex}
    | split list --regex $regex
    | drop
    | last $n_commands
    | flatten
    | append (seq 1 $min_term_width | each {' '} | str join)
    | prepend ''
    | str join (char nl)
    | to png $filename

    $filename
}

def now-fn []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}

def last-commands [
    $n_commands
]: nothing -> string {
    history | last ($n_commands + 1) | drop | get command | str trim | str join '+'
}

def to-safe-filename [
    --version (-v): int = 1 #version of shortening
    --prefix: string = ''
    --suffix: string = ''
    --regex: string = '[^A-Za-z0-9_А-Яа-я+]' # symbols to keep
    --date
]: string -> string {
    str replace -ra $regex '_'
    | str replace -ra '__+' '_'
    | if (($in | str length) > 220) {
        if $date {
            $'(now-fn)+($in | str substring ..220)' # make string uniq
        } else {
            $'($in | str substring ..220)($in | hash sha256 | str substring ..10)' # make string uniq
        }
    } else {}
    | $'($prefix)($in)($suffix)'

}
