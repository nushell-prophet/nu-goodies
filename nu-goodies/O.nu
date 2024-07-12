def nu-complete-macos-apps [] {
    ls /Applications -s | get name | each {str replace '.app' '' | $'"($in)"' }
}

export def main [
    filepath?: path
    --app (-a): string@'nu-complete-macos-apps' = '"Snagit 2022"' # app to open at
    --reveal (-r) # reveal app in finder
]: [path -> nothing, nothing -> nothing] {
    if $filepath == null {} else {$filepath}
    | if $reveal {
        ^open -R $in
    } else {
        ^open -a $app $in
    }
}
