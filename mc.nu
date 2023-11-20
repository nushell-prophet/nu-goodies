export def --env main [] {
    let $path = ($nu.temp-path | path join (random chars))
    ^mc -P $path
    if ($path | path exists) { 
        cd (open -r $path)
        rm $path
    }
}
