use normalize.nu
use bar.nu

# format `debug profile` output
#
# > debug profile {pin-text cyber} --max-depth 7 --spans | format profile | null
export def main [] {
    skip
    | update depth {|i| $i.depth - 1}
    | normalize duration_ms
    | update duration_ms_norm {bar $in --width 16}
    | insert fullspan {|i| view span $i.span.start $i.span.end
        | str replace -ar '(^|\n)\s+' ''
        | str substring 0..((term size).columns - 40 - ($i.depth * 2))}
    | insert hier {|i| seq 1 $i.depth
        | each {'│ '}
        | str join
        | $in + "├─" + ($i.fullspan)}
    | sort-by id
    | reject span source fullspan parent_id id depth
}
