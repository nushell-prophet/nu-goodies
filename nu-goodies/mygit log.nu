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

    let hist_backups_dir = '~/.config/nushell/history-backups/'
        | path expand

    let date_uniq = date now
        | format date '%F_%T_%f'
        | str replace -ra '([^\d_])' ''

    let temp_hist_folder = $hist_backups_dir
        | path join $date_uniq

    let $history_back_file = $temp_hist_folder
        | path join 'history.sqlite3'

    mkdir $temp_hist_folder

    sqlite3 $nu.history-path 'PRAGMA wal_checkpoint(FULL);'
    sqlite3 $nu.history-path $'.backup ($history_back_file)'

    sqlite3 $history_back_file ".dump history"
    | save ($temp_hist_folder | path join 'history_back.sql') -f

    let paths = [
            '~/.config/nushell'
            '~/.config/'
            '~/.visidata/'
        ]
        | path expand

    for $dir in $paths {
        try {
            print $dir '';
            cd $dir;
            git add --all
            git commit -a -m $message
        }
    }
}
