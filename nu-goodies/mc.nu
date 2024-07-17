# open midnight commander, cd to the last folder
export def --env main [
    path1?: path
    path2?: path
] {
    let $path = ($nu.temp-path | path join (random chars))
    if $path2 != null {
        ^mc $path1 $path2 -P $path
    } else if $path1 != null {
        ^mc $path1 -P $path
    } else {
        ^mc -P $path
    }
    if ($path | path exists) {
        cd (open -r $path)
        rm $path
    }
}
