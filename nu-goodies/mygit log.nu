# commit current version of dot files and apps settings
export def 'main' [
    --message (-m): string
] {
    let $message = ($message | default (date now | format date "%Y-%m-%d"))

    glob $'("~" | path expand)/.*' --no-dir --exclude [
        '.CFUserTextEncoding'
    ]
    | each {|i| cp $i ('~/.config/dot_home_dir' | path expand)}

    let paths = [
            '~/.config/nushell'
            '~/.config/'
            '~/git/nu_scripts'
            '~/.visidata/'
        ]
        | path expand

    for $dir in $paths {
        print $dir '';
        cd $dir;
        git add --all
        git commit -a -m $message
    }
}
