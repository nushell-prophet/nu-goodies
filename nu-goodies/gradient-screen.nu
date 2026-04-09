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

    let screen_size = if $rows == null {
            $term_size | values | math product
        } else {
            $term_size.columns * $rows
        }

    let pattern_len = $strings.0 | split chars | length
    let color_pairs = [(rand-hex-col2) (rand-hex-col2) (rand-hex-col2) (rand-hex-col2)]

    $env.gradient-screen-last-colors = $color_pairs

    let chars = build-screen-buffer $strings $screen_size --no-date=$no_date

    apply-gradient $chars $pattern_len $color_pairs $term_size.columns
    | if $echo { } else {
        print; sleep 2sec;
    }
}

def apply-gradient [
    chars: list<string>
    pattern_len: int
    color_pairs: list<list<string>>
    columns: int
]: nothing -> string {
    let pair_count = $color_pairs | length

    $chars
    | window $columns --stride $columns --remainder
    | enumerate
    | each {|row|
        let colors = $color_pairs | get ($row.index mod $pair_count)
        $row.item
        | window $pattern_len --stride $pattern_len --remainder
        | each { str join | ansi gradient --fgstart $colors.0 --fgend $colors.1 }
        | str join
    }
    | str join (char nl)
    | $'($in)(ansi reset)'
}

def build-screen-buffer [
    strings: list<string>
    screen_size: int
    --no-date
]: nothing -> list<string> {
    let pattern_chars = $strings.0 | split chars
    let pattern_len = $pattern_chars | length
    let date_text = date now | format date "%Y%m%d_%H%M%S"

    # Why: pad each filler text with trailing pattern chars so its length
    # is a multiple of pattern_len — keeps gradient windows aligned
    let filler_texts = $strings
        | skip
        | each {|i|
            str c $i ($pattern_chars | last ($pattern_len - ($i | str length) mod $pattern_len) | str join)
        }
        | append ''

    let filler_len = $filler_texts
        | str length
        | math sum

    # Why: clamp to 4 minimum so `random int 3..$repeat_count` is always
    # a valid range — fillers alone can exceed screen_size with many strings
    let repeat_count = [
        (($screen_size - $filler_len) // $pattern_len)
        4
    ] | math max

    let base = seq 0 $repeat_count
        | each { $strings.0 }

    $filler_texts
    | reduce -f $base {|i acc|
        $acc
        | insert (random int 3..$repeat_count) $i
    }
    | str join
    | split chars --grapheme-clusters
    | first $screen_size
    | if $no_date { } else {
        drop ($date_text | str length)
        | append ($date_text | split chars)
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
