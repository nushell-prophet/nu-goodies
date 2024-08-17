export def main [
    $n_last_commands: int = 2 # Number of recent commands (and outputs) to capture. Default is 1.
    --regex: string = '' # Regex to separate prompts from outputs. Default is ''.
    --lines_before_top_of_term: int = 100 # Lines from top of scrollback in Wezterm to capture.
    --min_term_width: int = 0
] {
    ^wezterm cli get-text --escapes --start-line ($lines_before_top_of_term * -1)
    | str replace -ra '(\r|\n)+$' ''
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
