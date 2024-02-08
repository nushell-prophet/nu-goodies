export def --env main [
    dir: path
] {
    mkdir $dir
    cd $dir
    wezterm cli set-tab-title $dir
}
