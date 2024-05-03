#wez-to-gif
export def main [
    ...rest: string
    --filename: path
    --font-family: string = "JetBrainsMono Nerd Font Mono"
    --font-size: int = 20
    --ascinema # copy ascinema here too
] {
    let $wezrec = ^wezterm record --cwd (pwd) -- $nu.current-exe --execute $'source $nu.env-path; clear; commandline edit -r ($rest | str join " ")'
        | complete
        | get stderr
        | str replace -r '.*\n.*\/var' '/var'
        | str trim -c (char nl)

    let $gif_name = $filename
        | default $'_wez_gif_(date now | format date `%s`).gif'
        | path expand

    print $wezrec

    if $ascinema {
        cp $wezrec .
    }

    ^agg --font-family $font_family --font-size $font_size -v $wezrec $gif_name
    print ''

    ^open -R $gif_name # reveal in finder
}
