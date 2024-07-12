# fill screen with repeated texts from arguments or $env.gradient-screen.texts
export def main [
    ...strings: string
    --no_date # don't append date
] {
    let $strings = $strings
        | if $in == [] {
            $env.gradient-screen?.texts?
            | default [
                '<nushell<is<awesome<'
                '<wezterm<is<awesome<'
                'and<you<are<awesome<'
            ]
        } else {}

    let $screen_size = term size | values | math product
    let $1_list = $strings.0 | split chars
    let $1_len = $1_list | length
    let $date_text = date now | format date "%Y%m%d_%H%M%S"

    let colors = rand_hex_col2

    let $other_strings = $strings
        | skip
        | each {|i|
            $'($i)($1_list | last ($1_len - ($i | str length) mod $1_len) | str join)'
        }
        | append ''

    let $other_len = $other_strings
        | str length
        | math sum

    let $n_chunks = ($screen_size - $other_len) // $1_len

    let $base = seq 0 $n_chunks
        | each {$strings.0}

    $other_strings
    | reduce -f $base {|i acc|
        $acc
        | insert (random int 3..$n_chunks) $i
    }
    | str join
    | split chars --grapheme-clusters
    | first $screen_size
    | if $no_date {} else {
        drop ($date_text | str length)
        | append ($date_text | split chars)
    }
    | window $1_len --stride $1_len --remainder
    | each {str join | ansi gradient --fgstart $colors.0 --fgend $colors.1}
    | str join
    | print; sleep 0.2sec;
}

def generate_colors [] {1..3 | each {(random int 0..255)}}

def make_hex [] {each {into binary --compact  | encode hex} | prepend '0x' | str join}

def check_colors [c0 c1 --threshold = 250] {
    ($c0 | zip $c1 | each {|i| ($i.0 - $i.1) ** 2} | math sum | math sqrt) > $threshold
}

def rand_hex_col2 [] {
    mut color0 = []
    mut color1 = []

    for pair in 1..30 {
        $color0 = (generate_colors)
        $color1 = (generate_colors)
        if (check_colors $color0 $color1) {
            break
        }
    }

    if not (check_colors $color0 $color1) {
        let rand = random int 100..180
        $color1 = ($color0 | each {($in + $rand) mod 255})
    }

    [$color0 $color1] | each {make_hex}
}
