export def main [
    main_text:string = '<nushell<is<awesome<'
    hidden_text: string = 'you<are<awesome<too'
    --frames_total: int = 500
    --frame_hidden: int = 495
    -n # don't quit
] {
    seq 0 $frames_total
    | each {$main_text | ansi gradient --fgstart '0x3719bd' --fgend '0xa9be52'}
    | insert $frame_hidden ($hidden_text | ansi gradient --fgstart '0x3719bd' --fgend '0xa9be52')
    | str join
    | print; sleep 0.2sec;

    if not $n {exit}
}
