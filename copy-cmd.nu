# copy this command to clipboard
export def main [] {
    history
    | last
    | get command
    | str replace -r '\| copy-cmd.*' ''
    | str trim
    | pbcopy
}
