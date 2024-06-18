#wez-to-gif
export def main [
    command: string = ''
    --filename: path
    --font-family: string = "JetBrainsMono Nerd Font Mono"
    --font-size: int = 20
    --ascinema # copy ascinema here too
] {
    let $wezrec = ^wezterm record --cwd (pwd) -- $nu.current-exe --execute $'source $nu.env-path; clear; ($command)'
        | complete
        | get stderr
        | str replace -r '.*\n.*\/var' '/var'
        | str trim -c (char nl)

    let target_folder = '/Users/user/temp/wezterm-asciinemas'
        | path join $'gif_(pwd | path split | last)'
        | $'($in)(mkdir $in)'


    let $gif_name = $target_folder
        | path join ($filename
            | default $'_wez_gif_(date now | format date `%s`).gif')

    print $wezrec

    cp $wezrec $target_folder

    ^agg --font-family $font_family --font-size $font_size -v $wezrec $gif_name
    print ''

    ^open -R $gif_name # reveal in finder
}
