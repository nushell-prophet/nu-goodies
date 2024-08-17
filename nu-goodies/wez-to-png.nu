# capture wezterm scrollback, split by prompts, output chosen to an image file
# uses nu_plugin_image
# https://wezfurlong.org/wezterm/index.html
# https://github.com/FMotalleb/nu_plugin_image/

use wez-to-ansi.nu

# capture wezterm scrollback, split by prompts, output chosen ones to an image file
export def main [
    $n_last_commands: int = 2 # Number of recent commands (and outputs) to capture.
    --output_path: path = '' # Path for saving output images.
] {
    let $output_path = $output_path
        | if $in != '' {} else {
            let filename = last-commands $n_last_commands
                | to-safe-filename --prefix 'wez-out-' --suffix '.png' --date

            ['/Users/user/temp/freeze_images/' (pwd | path split | last)]
            | path join
            | $'($in)(mkdir $in)'
            | path join $filename
        }

    let out = wez-to-ansi $n_last_commands

    $out | freeze --config user -o ($output_path | str replace -a '.png' '.svg')
    $out | freeze --config user -o ($output_path | str replace -a '.png' '.webp')
    $out | freeze --config user -o $output_path
    $out | save -f ($output_path | str replace -a '.png' '.ans')
    # | to png $output_path

    ^open -R $output_path
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
    | if $date {
        $'(now-fn)+($in | str substring ..30)' # make string uniq
    } else if (($in | str length) > 30) {
        $'($in | str substring ..30)($in | hash sha256 | str substring ..10)' # make string uniq
    } else {}
    | $'($prefix)($in)($suffix)'
}
