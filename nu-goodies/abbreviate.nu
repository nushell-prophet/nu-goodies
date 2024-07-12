# > 1..10 | wrap a | merge ($in | rename b) | abbreviate -c
# ╭─a──┬─b──╮
# │  1 │  1 │
# │  2 │  2 │
# │  3 │  3 │
# │ *  │ *  │
# │  8 │  8 │
# │  9 │  9 │
# │ 10 │ 10 │
# ╰────┴────╯
export def main [
    --copy (-c) # strip ansi codes from output table and copy it to clipboard
] {
    let $value = $in
    let $value_desc = $value | describe
    let $val_length = if $value_desc =~ '^(table|list)' {
            $value | length
        } else {
            1
        }

    if $val_length > 6 {
        $value | first 3
        | append ($value | columns | reduce -f {} {|col acc| $acc | merge {$col : '…'}})
        | append ($value | last 3)
    } else {
        $value
    }
    | if $copy {
        table
        | ansi strip
        | pbcopy
    } else {}
}
