###file O.nu
def completions-macos-apps []: nothing -> list<string> {
    ls /Applications --short-names | get name | each { str replace '.app' '' | $'"($in)"' }
}

# Open a file in the specified macOS application or reveal it in Finder (--app flag supports completions)
# > O O.nu --app "Sublime Text"
export def 'O' [
    filepath?: path
    --app (-a): string@'completions-macos-apps' = 'Snagit 2022.app' # App to open with
    --reveal (-r) # Reveal app in Finder
]: [path -> nothing nothing -> nothing] {
    if $filepath == null { } else { $filepath }
    | if $reveal {
        ^open -R $in
    } else {
        ^open -a $app $in
    }
}

###file ramdisk-create.nu
# Create ramdisk in macOS
export def 'ramdisk-create' [
    size: filesize = 4194304kb
]: nothing -> nothing {
    let vol = (hdiutil attach -nobrowse -nomount $'ram://($size | into int | $in * 1.024 / 1000 * 2)' | str trim);
    sleep 2sec
    (^diskutil erasevolume HFS+ RAMDisk $vol)
    cd /Volumes/RAMDisk
}

###file figlet-demo.nu
# Preview text in all available figlet fonts
export def figlet-demo [text: string]: nothing -> record {
    glob /opt/homebrew/Cellar/figlet/2.2.5/share/figlet/fonts/*.flf
    | par-each --keep-order {|font|
        let name = $font | path basename

        $text
        | figlet -f $name -C utf8
        | wrap $name
    }
    | reduce {|i| merge $i }
}
