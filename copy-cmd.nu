# copy this command to clipboard
use clip.nu
export def main [] {
    history
    | last
    | get command
    | str replace -r '\| copy-cmd.*' ''
    | str trim
    | clip
}


