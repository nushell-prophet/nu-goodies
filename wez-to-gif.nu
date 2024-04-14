#wez-to-gif
export def main [
    filename?: path
] {
    let $wezrec = (^wezterm record | complete | get stderr | str replace -r '.*\n.*\/var' '/var' | str trim -c (char nl))
    let $gif_name = $filename
        | default ($'_wez_gif_(date now | format date '%s').gif')

    ^agg --font-family "JetBrainsMono Nerd Font Mono" --font-size 20 -v $wezrec $gif_name
    $gif_name
}
