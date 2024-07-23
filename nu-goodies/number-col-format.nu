use number-format.nu

# Format number column in a table using number-format
#
# > [[a]; [123456.678] [2345.8900]] | number-col-format a --denom wt --decimals 2 --significant_digits 3
# ╭──────a───────╮
# │ 123_000.00wt │
# │   2_340.00wt │
# ╰──────────────╯
export def main [
    column_name: string # A column name to format
    --thousands_delim (-t) = '_' # Thousands delimiter: number-format 1000 -t ': 1'000
    --decimals (-d) = 0 # Number of digits after decimal delimiter: number-format 1000.1234 -d 2: 1000.12
    --denom (-D) = '' # Denom `--denom "Wt": number-format 1000 --denom 'Wt': 1000Wt
    --significant_digits: int = 0 # The number of first digits to display, others will become 0
] {
    let $input = $in

    if $column_name not-in ($input | columns) {
        error make {'msg': $'There is no ($column_name) in columns'}
    }

    let $thousands_delim_length = $thousands_delim | str length --grapheme-clusters

    let $integers = $input
        | get $column_name
        | math max
        | split row '.'
        | get 0
        | str length
        | if $thousands_delim_length > 0 {
                $in * ((3 + $thousands_delim_length) / 3 - 0.001) | math floor
        } else {}
        | append (
            $column_name | str length
            | $in - $decimals - $thousands_delim_length - ($denom | str length --grapheme-clusters)
        )
        | math max


    $input
    | upsert $column_name {|i|
        ( number-format ($i | get $column_name)
            --denom $denom --decimals $decimals
            --thousands_delim $thousands_delim --integers $integers
            --significant_digits $significant_digits)
    }
}
