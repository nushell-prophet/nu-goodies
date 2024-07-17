# Format big numbers nicely
export def main [
    num? # Number to format
    --thousands_delim (-t): string = '_' # Thousands delimiter: number-format 1000 -t ': 1'000
    --integers (-w): int = 0 # Length of padding whole-part digits: number-format 123 -w 6:    123
    --significant_integers: int = 3 # The number of first integers to display, others will become 0
    --decimals (-d): int = 0 # Number of digits after decimal delimiter: number-format 1000.1234 -d 2: 1000.12
    --denom (-D): string = '' # Denom `--denom "Wt": number-format 1000 --denom 'Wt': 1000Wt
    --color: string = 'green'
] {
    let $in_num = $in

    let parts = $num
        | default $in_num
        | into string
        | split chars
        | if $significant_integers == 0 {} else {
            enumerate
            | each {
                |i| if $i.item == '.' {'.'} else { # if decimals are in range - they miss one symbol, better to fix
                    if $i.index < $significant_integers {$i.item} else {0}}
                }
        }
        | split list '.'

    let $whole_part = $parts.0
        | reverse
        | window 3 -s 3 --remainder
        | each {|i| $i | reverse | str join}
        | reverse
        | str join $thousands_delim
        | if $integers == 0 { } else {
            fill -w $integers -c ' ' -a r
        }

    let dec_part = if $decimals == 0 {
            ''
        } else {
            $parts.1?
            | default [0]
            | first $decimals
            | str join
            | '.' + $in
            | fill -w ($decimals + 1) -c '0' -a l
        }

    $"(ansi $color)($whole_part)($dec_part)(ansi reset)(ansi green_bold)($denom)(ansi reset)"
}
