# makedir and cd into it
export def --env main [
    target_dir
    -d # use standard directory
    --dest_dir: path = '/Users/user/temp'
] {
    let $dir = (
        if $d or ($dest_dir != '/Users/user/temp') {
            $dest_dir | path join ($target_dir | str replace -a ' ' '_')
        } else {$target_dir}
        | path expand
    )

    mkdir $dir
    cd $dir
    wezterm cli set-tab-title ($dir | path basename)
}
