# output a command from a pipe where `example` used, and truncate the output table
use abbreviate.nu
export def main [
    --dont_copy (-C)
    --dont_comment (-H)
    --indentation_spaces (-i): int = 1
    --first: int
] {
    let $in_table = abbreviate
        | table
        | if $dont_comment {} else {ansi strip}

    history
    | last
    | get command
    | str replace -r '\| example.*' ''
    | $'> ($in)(char nl)($in_table)'
    | if $dont_comment {} else {
        lines
        | each {|i| $'#(seq 1 $indentation_spaces | each {" "} | str join '')($i)'}
        | str join (char nl)
    }
    | if $first != null {
        lines
        | if ($in | length | $in <= $first) {} else {
            first $first
            | append '...'
        }
        | str join (char nl)
    } else {}
    | if $dont_copy {} else {
        let $i = $in
        $i | pbcopy
        $i
    }
}
