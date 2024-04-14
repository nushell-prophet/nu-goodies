export def 'main' [
    --message (-m): string
] {
    let $message = ($message | default (date now | format date "%Y-%m-%d"))

    glob $'("~" | path expand)/.*' --no-dir
    | where $it != '/Users/user/.CFUserTextEncoding'
    | each {|i| cp $i ('~/.config/dot_home_dir' | path expand)}

    [
        '~/Library/Application Support/nushell'
        '~/apps-files/github/nu_scripts/'
        '~/.config/'
        '~/.visidata/'
    ]
    | path expand
    | each { |dir|
        print $dir;
        cd $dir;
        git add --all
        git commit -a -m $message
    }
}
