export def main [
    $n_last_commands: int = 2 # Number of recent commands (and outputs) to capture.
    --regex: string = '^>' # Regex to separate prompts from outputs. Default is ''.
    --lines_before_top_of_term: int = 100 # Lines from top of scrollback in Wezterm to capture.
    --min_term_width: int = 0
] {

    # let $regex = '^' + (ansi green_italic) + '>'

    ^wezterm cli get-text --escapes --start-line ($lines_before_top_of_term * -1)
    | str replace -a $"\n(ansi blue_bold)> " "\n>"
    | str replace -ra '(\r|\n)+$' ''
    | inspect
    | lines
    | skip until {|i| $i =~ $regex}
    | split list --regex $regex
    | drop
    | last $n_last_commands
    | flatten
    | if $min_term_width == 0 { } else {
        prepend (seq 1 $min_term_width | each {' '} | str join)
    }
    | str join (char nl)
}
