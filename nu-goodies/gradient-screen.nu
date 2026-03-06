use str.nu ["str c"]

# Display gradient screen and exit the shell
export def 'bye' [
    ...strings: string
    --no-date # Don't append date
    -n # don't quit
]: nothing -> nothing {
    main ...$strings --no-date=$no_date
    if not $n { exit }
}

# Fill screen with repeated texts from arguments or $env.gradient-screen.texts with random color gradient
export def --env main [
    ...strings: string
    --no-date # Don't append date
    --echo
    --rows: int
]: nothing -> any {
    let strings = $strings
        | if $in == [] {
            $env.gradient-screen?.texts?
            | default [
                '<nushell<is<awesome<'
                '<wezterm<is<awesome<'
                'and<you<are<awesome<'
            ]
        } else { }

    let term_size = term size

    let screen_size = $term_size
        | if $rows == null { values } else {
            $in.columns * $rows
        }
        | math product

    let 1_list = $strings.0 | split chars
    let 1_len = $1_list | length
    let date_text = date now | format date "%Y%m%d_%H%M%S"

    let colors = rand-hex-col2

    $env.gradient-screen-last-colors = $colors

    let other_strings = $strings
        | skip
        | each {|i|
            str c $i ($1_list | last ($1_len - ($i | str length) mod $1_len) | str join)
        }
        | append ''

    let other_len = $other_strings
        | str length
        | math sum

    let n_chunks = ($screen_size - $other_len) // $1_len

    let base = seq 0 $n_chunks
        | each { $strings.0 }

    let output = $other_strings
        | reduce -f $base {|i acc|
            $acc
            | insert (random int 3..$n_chunks) $i
        }
        | str join
        | split chars --grapheme-clusters
        | first $screen_size
        | if $no_date { } else {
            drop ($date_text | str length)
            | append ($date_text | split chars)
        }
        | window $1_len --stride $1_len --remainder
        | each { str join | ansi gradient --fgstart $colors.0 --fgend $colors.1 }
        | str join

    split-ansi-chars $output
    | window $term_size.columns --stride $term_size.columns
    | each { str join }
    | str join (char nl)
    | $'($in)(ansi reset)'
    | if $echo { } else {
        print; sleep 2sec;
    }
}

def split-ansi-chars [s: string]: nothing -> list<string> {
    # Pattern to match: escape sequence + one character (no reset needed for gradients)
    let pat = "(\e\\[[0-9;]*m)+(.)"

    let nul = char nul

    $s
    | str replace -ar $pat $'$1$2($nul)' # capture color + char, add delimiter
    | split row $nul
    | compact --empty
}

def generate-colors []: nothing -> list<int> { 1..3 | each { (random int 0..255) } }

def make-hex []: list<int> -> string { each { into binary --compact | encode hex } | prepend '0x' | str join }

def check-colors [c0: list<int> c1: list<int> --threshold: int = 250]: nothing -> bool {
    ($c0 | zip $c1 | each {|i| ($i.0 - $i.1) ** 2 } | math sum | math sqrt) > $threshold
}

def rand-hex-col2 []: nothing -> list<string> {
    # Try up to 30 times to find contrasting colors
    let pair = generate {|i = 0|
        if $i >= 30 { return {} }

        let c0 = generate-colors
        let c1 = generate-colors

        if (check-colors $c0 $c1) {
            {out: [$c0 $c1]}
        } else {
            {next: ($i + 1)}
        }
    }
        | get 0?

    # Fallback: force contrast if no good pair found
    $pair | default {
        let c0 = generate-colors
        let rand = random int 100..180
        [$c0 ($c0 | each { ($in + $rand) mod 255 })]
    }
    | each { make-hex }
}
