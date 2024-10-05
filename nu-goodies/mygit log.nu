# commit current version of dot files and apps settings
export def 'main' [
    --message (-m): string
] {
    let $message = $message
        | default (date now | format date "%Y-%m-%d")

    let $dot_dir = '~/.config/dot_home_dir'
        | path expand

    $nu.home-path
    | path join '.*'
    | glob $in -d 1 --no-dir --exclude [ '.CFUserTextEncoding' ]
    | par-each {|i| cp --update $i $dot_dir}

    backup-history

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

export def backup-history [] {
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

    # sqlite3 $nu.history-path 'PRAGMA wal_checkpoint(FULL);'
    sqlite3 $nu.history-path $'.backup ($history_back_file)'

    sqlite3 $history_back_file ".dump history"
    | save ($hist_backups_dir | path join 'history_back.sql') -f
}
