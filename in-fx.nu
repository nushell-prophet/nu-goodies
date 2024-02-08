export def --wrapped main [
    ...rest
] {
    to json -r
    | ansi strip
    | ^fx ...$rest
}
