# Print a string colorfully with bells and whistles
export def main [
    text: string
    --color (-c): any = 'default'
    --highlight_color (-h): any = 'green_bold'
    --frame_color (-r): any = 'dark_gray'
    --frame (-f): string = '' # A symbol (or a string) to frame a text
    --lines_before (-b): int = 0 # A number of new lines before a text
    --lines_after (-a): int = 1 # A number of new lines after a text
    --echo (-e) # Echo text string instead of printing
    --keep_single_breaks # Don't remove single line breaks
    --width (-w): int = 80 # The total width of text to wrap it
    --indent (-i): int = 0 # indent output by numer of spaces
    --alignment: string = 'left' # aligment of text
] {
    let $width_safe = width-safe $width $indent

    $text
    | wrapit $keep_single_breaks $width_safe $indent
    | colorit $highlight_color $color
    | alignit $alignment $width_safe
    | if $frame != '' {
        frameit $width_safe $frame $frame_color
    } else {}
    | indentit $indent
    | newlineit $lines_before $lines_after
    | if $echo { } else { print -n $in }
}

# I `export` commands here to be availible for testing, yet to be included
# in the same file, so cprint could be just copied to other projects.

export def width-safe [
    $width
    $indent
] {
    term size
    | get columns
    | [$in $width] | math min
    | $in - $indent
    | [$in 1] | math max # term size gives 0 in tests
}

export def wrapit [
    $keep_single_breaks
    $width_safe
    $indent
] {
    str replace -r -a '(?m)^[\t ]+' ''
    | if $keep_single_breaks { } else {
        remove_single_nls
    }
    | str replace -r -a '[\t ]+$' ''
    | str replace -r -a $"\(.{1,($width_safe)}\)\(\\s|$\)|\(.{1,($width_safe)}\)" "$1$3\n"
    | str replace -r $'(char nl)$' '' # trailing new line
}

export def remove_single_nls [] {
    str replace -r -a '(\n[\t ]*(\n[\t ]*)+)' '⏎'
    | str replace -r -a '\n' ' ' # remove single line breaks used for code formatting
    | str replace -a '⏎' "\n\n"
}

export def newlineit [
    $before
    $after
] {
    $"((char nl) | str repeat $before)($in)((char nl) | str repeat $after)"
}

export def frameit [
    $width_safe
    $frame
    $frame_color
] {
    let $input = $in

    $frame
    | str repeat $width_safe
    | str substring --grapheme-clusters 1..($width_safe) # in case that frame has more than 1 chars
    | $'(ansi $frame_color)($in)(ansi reset)'
    | $in + "\n" + $input + "\n" + $in
}

export def colorit [
    $highlight_color
    $color
] {
    str replace -r -a '\*([\s\S]+?)\*' $'(ansi reset)(ansi $highlight_color)$1(ansi reset)(ansi $color)'
    | $'(ansi $color)($in)(ansi reset)'
}

export def alignit [
    $alignment: string
    $width_safe
] {
    lines
    | each {
        fill --alignment $alignment --width $width_safe
    }
    | str join (char nl)
}


export def indentit [
    $indent
] {
    str replace -r -a '(?m)^(.)' $'((char sp) | str repeat $indent)$1'
}

def 'str repeat' [
    $n
] {
    let $text = $in
    seq 1 $n | each {$text} | str join
}
