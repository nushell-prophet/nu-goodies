# shortcut for pbpaste and pbcopy. But is it needed?
export def cb [
    --paste
] {
    if $paste or ($in == null) {
        pbpaste
    } else {
        pbcopy
    }
}
