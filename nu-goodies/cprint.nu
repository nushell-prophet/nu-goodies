use str.nu

# Print a string colorfully with bells and whistles.
export def main [
    ...text_args
    --color (-c): any = 'default'
    --highlight_color (-h): any = 'green_bold'
    --frame_color (-r): any = 'dark_gray'
    --frame (-f): string = '' # A symbol (or a string) to frame a text
    --before (-b): int = 0 # A number of new lines before a text
    --after (-a): int = 1 # A number of new lines after a text
    --echo (-e) # Echo text string instead of printing
    --keep_single_breaks # Don't remove single line breaks
    --width (-w): int = 80 # The width of text to format it
    --indent (-i): int = 0
    --alignment: string = 'left'
] {
    let $width_safe = term size
        | get columns
        | [$in ($width + $indent)] | math min
        | [$in 1] | math max # term size gives 0 in tests

    $text_args
    | str join ' '
    | wrapit $keep_single_breaks $width_safe $indent
    | colorit $highlight_color $color
    | alignit $alignment $width_safe
    | if $frame != '' {
        frameit $width_safe $frame $frame_color
    } else {}
    | newlineit $before $after
    | if $echo { } else { print -n $in }
}

def wrapit [
    $keep_single_breaks
    $width_safe
    $indent
] {
    str replace -r -a '(?m)^[\t ]+' ''
    | if $keep_single_breaks { } else {
        str replace -r -a '(\n[\t ]*(\n[\t ]*)+)' '⏎'
        | str replace -r -a '\n' ' ' # remove single line breaks used for code formatting
        | str replace -a '⏎' "\n\n"
    }
    | str replace -r -a '[\t ]+$' ''
    | str replace -r -a $"\(.{1,($width_safe - $indent)}\)\(\\s|$\)|\(.{1,($width_safe - $indent)}\)" "$1$3\n"
    | str replace -r $'(char nl)$' '' # trailing new line
    | str replace -r -a '(?m)^(.)' $'((char sp) | str repeat $indent)$1'
}

def newlineit [
    $before
    $after
] {
    $"((char nl) | str repeat $before)($in)((char nl) | str repeat $after)"
}

def frameit [
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

def colorit [
    $highlight_color
    $color
] {
    str replace -r -a '\*([\s\S]+?)\*' $'(ansi reset)(ansi $highlight_color)$1(ansi reset)(ansi $color)'
    | $'(ansi $color)($in)(ansi reset)'
}

def alignit [
    $alignment: string
    $width_safe
] {
    lines
    | each {
        fill --alignment $alignment --width $width_safe
    }
    | str join (char nl)
}
