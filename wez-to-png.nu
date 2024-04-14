# capture wezterm scrollback, split by prompts, output chosen to an image file
# uses nu_plugin_image
# https://wezfurlong.org/wezterm/index.html
# https://github.com/FMotalleb/nu_plugin_image/

# capture wezterm scrollback, split by prompts, output chosen ones to an image file
export def main [
    $n_last_commands: int = 1 # Number of recent commands (and outputs) to capture. Default is 1.
    --lines_before_top_of_term: int = 10000 # Lines from top of scrollback in Wezterm to capture.
    --regex: string = '' # Regex to separate prompts from outputs. Default is ''.
    --min_term_width: int = 60
    --output_path: path = '' # Path for saving output images.
    --date # Append date to image filenames for uniqueness (ignored if `--output_path` is set)
] {
    let $output_path: path = (
        $output_path
        | if $in != '' {} else {
            last-commands $n_last_commands
            | to-safe-filename --prefix 'wez-out-' --suffix '.png' --date=$date
        }
    )

    ^wezterm cli get-text --escapes --start-line ($lines_before_top_of_term * -1)
    | str replace -ra '(\r|\n)+$' ''
    | lines
    | skip until {|i| $i =~ $regex}
    | split list --regex $regex
    | drop
    | last $n_last_commands
    | flatten
    | append (seq 1 $min_term_width | each {' '} | str join)
    | prepend ''
    | str join (char nl)
    | to png $output_path

    $output_path
}

def now-fn []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}

def last-commands [
    $n_last_commands
]: nothing -> string {
    history
    | last ($n_last_commands + 1)
    | drop # drop the last command to initiate image capture
    | get command
    | str trim
    | str join '+'
}

def to-safe-filename [
    --prefix: string = ''
    --suffix: string = ''
    --regex: string = '[^A-Za-z0-9_А-Яа-я+]' # symbols to keep
    --date
]: string -> string {
    str replace -ra $regex '_'
    | str replace -ra '__+' '_'
    | if (($in | str length) > 50) {
        if $date {
            $'(now-fn)+($in | str substring ..50)' # make string uniq
        } else {
            $'($in | str substring ..50)($in | hash sha256 | str substring ..10)' # make string uniq
        }
    } else {}
    | $'($prefix)($in)($suffix)'
}
