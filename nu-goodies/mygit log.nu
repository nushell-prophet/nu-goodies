# commit current version of dot files and apps settings
export def 'main' [
    --message (-m): string
] {
    let $message = $message
        | default (date now | format date "%Y-%m-%d")

    glob $'("~" | path expand)/.*' --no-dir --exclude [
        '.CFUserTextEncoding'
    ]
    | each {|i| cp --update $i ('~/.config/dot_home_dir' | path expand)}

    open $nu.history-path
    | query db 'PRAGMA wal_checkpoint(FULL);'

    let temp_hist_folder = date now
        | format date '%F_%T_%f'
        | str replace -ra '([^\d_])' ''
        | $'~/.config/nushell/history-backups/($in)/'
        | path expand

    mkdir $temp_hist_folder

    sqlite3 $nu.history-path $'.backup ($temp_hist_folder)/hist.db'

    cp ~/.config/nushell/history.sqlite* $temp_hist_folder

    let paths = [
            '~/.config/nushell'
            '~/.config/'
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
