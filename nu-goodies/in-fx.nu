# convert datastructure to json and open it in fx
export def --wrapped main [
    ...rest
] {
    to json -r
    | ansi strip
    | ^fx ...$rest
}
