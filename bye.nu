export def main [
    1:string = '<nushell<is<awesome<'
    2:string = '<wezterm<is<awesome<'
    3:string = 'and<you<are<awesome<'
    --frames: int = 500
    -n # don't quit
] {
    seq 0 $frames
    | each {$1 | ansi gradient --fgstart '0x3719bd' --fgend '0xa9be52'}
    | insert ($frames - (random int 2..10)) (
        $3 | ansi gradient --fgstart '0x3719bd' --fgend '0xa9be52'
    )
    | insert ($frames - (random int 8..20)) (
        $2 | ansi gradient --fgstart '0x3719bd' --fgend '0xa9be52'
    )
    | str join
    | print; sleep 0.2sec;

    if not $n {exit}
}
