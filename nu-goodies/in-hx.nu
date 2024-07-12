# opens piped-in results in hx, output back the saved file
export def main [
    --path (-p) # output path of the file
] {
    let $input = $in
    let $type = $input | describe
    let $filename = $nu.temp-path | path join (date now | format date "%Y%m%d_%H%M%S" | $in + '.nu')

    $input
    | if ($type =~ '(table|record|list)') { to nuon } else {}
    | if ($type =~ '(raw type|string)') { ansi strip } else {}
    | save $filename

    hx $filename

    if $path {
        print $path
    } else {
        commandline edit -r (open $filename)
    }
}
