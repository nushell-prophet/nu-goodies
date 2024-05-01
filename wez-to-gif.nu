#wez-to-gif
export def main [
    filename?: path
    --font-family: string = "JetBrainsMono Nerd Font Mono"
    --font-size: int = 20
] {
    let $wezrec = ^wezterm record --cwd (pwd)
        | complete
        | get stderr
        | str replace -r '.*\n.*\/var' '/var'
        | str trim -c (char nl)

    let $gif_name = $filename
        | default $'_wez_gif_(date now | format date `%s`).gif'
        | path expand

    ^agg --font-family $font_family --font-size $font_size -v $wezrec $gif_name
    print ''
    $gif_name
}
