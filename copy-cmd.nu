# copy this command to clipboard
use std clip
export def main [] {
    history
    | last
    | get command
    | str replace -r '\| copy-cmd.*' ''
    | str trim
    | clip
}


