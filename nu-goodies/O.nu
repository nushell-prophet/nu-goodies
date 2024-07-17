def nu-complete-macos-apps [] {
    ls /Applications -s | get name | each {str replace '.app' '' | $'"($in)"' }
}

# Open a file in the specified macOS application or reveal it in Finder (--app flag supports completions)
# > O O.nu --app "Sublime Text"
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
