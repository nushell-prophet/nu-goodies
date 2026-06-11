# Render any value as lines of text
def to-lines []: any -> list<string> {
    table | into string | lines
}

# Truncate to a visible width while preserving ANSI escape codes.
# Why: `str substring --grapheme-clusters` counts ANSI bytes as graphemes, so we
# walk the string and skip CSI sequences from the visible count.
def truncate-visible [width: int]: string -> string {
    let chars = $in | split chars
    let n = $chars | length
    let esc = "\u{1b}"
    mut out = ''
    mut i = 0
    mut visible = 0
    mut state = 'normal'
    while $i < $n {
        let c = $chars | get $i
        match $state {
            'normal' => {
                if $c == $esc {
                    $out = $out + $c
                    $state = 'after_esc'
                } else if $visible < $width {
                    $out = $out + $c
                    $visible = $visible + 1
                } else {
                    break
                }
            }
            'after_esc' => {
                $out = $out + $c
                $state = if $c == '[' { 'in_csi' } else { 'normal' }
            }
            'in_csi' => {
                $out = $out + $c
                if ($c =~ '[A-Za-z]') {
                    $state = 'normal'
                }
            }
        }
        $i = $i + 1
    }
    $out + (ansi reset)
}

# Center text within terminal width
#
# With --vertical, also pads with blank lines so the block sits in the
# vertical middle of the terminal.
export def 'screen center' [
    --factor: int = 1 # Divide terminal width by this factor
    --vertical (-v) # Also center vertically within terminal height
]: any -> string {
    let input = $in | to-lines | str trim --right

    let max_length = $input | each { ansi strip | str length --grapheme-clusters } | math max
    let term_width = (term size).columns / $factor
    let left_pad = [0 (($term_width - $max_length) // 2)] | math max
    let padding = ('' | fill --character ' ' --width ($left_pad | into int))

    let centered = $input | each {|line| $padding + $line }

    let centered = if $vertical {
        let top_pad = [0 ((((term size).rows - ($input | length)) // 2))] | math max
        (0..<$top_pad | each { '' }) ++ $centered
    } else {
        $centered
    }

    $centered | str join (char nl)
}

# Clear the screen, show input centered on both axes as a splash, and
# wait for a keypress before returning the prompt
export def 'screen splash' [
    --factor: int = 1 # Divide terminal width by this factor
    --no-wait # Show the splash and return immediately, without waiting for a keypress
]: any -> nothing {
    clear
    print ($in | screen center --factor $factor --vertical)
    if not $no_wait {
        input listen --types [key] | ignore
    }
}

# Tile another output to the right of the piped input
#
# > "ab\ncd" | tile-right { "12\n34" }
# ab  12
# cd  34
export def 'tile-right' [
    right: closure # Closure producing the right panel
    --gap: int = 2 # Number of spaces between panels
    --no-truncate (-T) # Don't truncate lines to terminal width
]: any -> string {
    let left = $in | to-lines
    let right_lines = do $right | to-lines

    let left_width = $left | each { ansi strip | str length --grapheme-clusters } | math max
    let left_n = $left | length
    let right_n = $right_lines | length
    let gap_str = ('' | fill --character ' ' --width $gap)

    let width = if $no_truncate { 0 } else { (term size).columns }

    $left
    | append (seq 1 ($right_n - $left_n) | each { '' })
    | each { fill --width $left_width }
    | zip ($right_lines | append (seq 1 ($left_n - $right_n) | each { '' }))
    | each {|pair| $pair.0 + $gap_str + $pair.1 }
    | if not $no_truncate {
        each {|line|
            if ($line | ansi strip | str length --grapheme-clusters) > $width {
                $line | truncate-visible $width
            } else { $line }
        }
    } else { }
    | str join (char nl)
}

# Tile another output below the piped input
#
# > "ab" | tile-down { "cd" }
# ab
# cd
export def 'tile-down' [
    bottom: closure # Closure producing the bottom panel
    --gap: int = 0 # Number of blank lines between panels
]: any -> string {
    let separator = 1..($gap + 1) | each { (char nl) } | str join
    ($in | to-lines | str join (char nl)) + $separator + (do $bottom | to-lines | str join (char nl))
}

# Tile another output to the left of the piped input
export def 'tile-left' [
    left: closure # Closure producing the left panel
    --gap: int = 2 # Number of spaces between panels
    --no-truncate (-T) # Don't truncate lines to terminal width
]: any -> string {
    let right = $in
    do $left | tile-right --no-truncate=$no_truncate --gap $gap { $right }
}

# Tile another output above the piped input
export def 'tile-up' [
    top: closure # Closure producing the top panel
    --gap: int = 0 # Number of blank lines between panels
]: any -> string {
    let bottom = $in
    do $top | tile-down --gap $gap { $bottom }
}
