export def --env main [
    target_dir: path
    -d # use standard directory
    --dest_dir: path = '/Users/user/temp'
] {
    let $dir = (if $d or ($dest_dir != '/Users/user/temp') {
            $dest_dir | path join $target_dir
        } else {$target_dir})
    
    mkdir $dir
    cd $dir
    wezterm cli set-tab-title $target_dir
}
