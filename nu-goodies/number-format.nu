use significant-digits.nu

# Format big numbers nicely
#
# > number-format 1000 --thousands_delim "'"
# 1'000
#
# > number-format 123 --integers 6
#    123
#
# > number-format 1000.1234 --decimals 2
# 1_000.12
#
# > number-format 1000 --denom 'Wt'
# 1_000Wt
export def main [
    num? # Number to format
    --thousands_delim (-t): string = '_' # Thousands delimiter
    --integers (-i): int = 0 # Length of padding whole-part digits
    --significant_digits: int = 0 # The number of first digits to display, others will become 0
    --decimals (-d): int = 0 # Number of digits after decimal delimiter
    --denom (-D): string = '' # Denom
    --color: string = 'green'
] {
    let $in_num = $in

    let parts = $num
        | default $in_num
        | if $significant_digits == 0 {} else {
            significant-digits $significant_digits
        }
        | into string
        | split chars
        | split list '.'

    let $whole_part = $parts.0
        | reverse
        | window 3 -s 3 --remainder
        | each {reverse | str join}
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
