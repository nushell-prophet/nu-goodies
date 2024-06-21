# capture wezterm scrollback, split by prompts, output chosen to an image file
# uses nu_plugin_image
# https://wezfurlong.org/wezterm/index.html
# https://github.com/FMotalleb/nu_plugin_image/

use wez-to-ansi.nu

# capture wezterm scrollback, split by prompts, output chosen ones to an image file
export def main [
    $n_last_commands: int = 10 # Number of recent commands (and outputs) to capture. Default is 1.
    --output_path: path = '' # Path for saving output images.
    --date # Append date to image filenames for uniqueness (ignored if `--output_path` is set)
] {
    let $output_path = $output_path
        | if $in != '' {} else {
            last-commands $n_last_commands
            | to-safe-filename --prefix 'wez-out-' --suffix '.png' --date=$date
        }
        | [(pwd) $in]
        | path join

    wez-to-ansi $n_last_commands
    | freeze -o $output_path
    # | to png $output_path

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
    | str join '_'
}

def to-safe-filename [
    --prefix: string = ''
    --suffix: string = ''
    --regex: string = '[^A-Za-z0-9_А-Яа-я+]' # symbols to keep
    --date
]: string -> string {
    str replace -ra $regex '_'
    | str replace -ra '__+' '_'
    | if (($in | str length) > 30) {
        if $date {
            $'(now-fn)+($in | str substring ..30)' # make string uniq
        } else {
            $'($in | str substring ..30)($in | hash sha256 | str substring ..10)' # make string uniq
        }
    } else {}
    | $'($prefix)($in)($suffix)'
}
