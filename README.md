# nu-goodies

Some of my nushell commands.

## Quickstart

```nushell no-run
> git clone https://github.com/nushell-prophet/nu-goodies
> cd nu-goodies
> use nu-goodies *
```

## cprint

```nu no-output
let $sample_text = open nu-goodies/lazytests/TheSongoftheFalcon.txt | lines | first 6 | str join (char nl)
$sample_text | freeze -o media/0_bare_example.png --language text | null
```

![$sample_text](media/0_bare_example.png)

```nu no-output
cprint $sample_text --width 40 --echo | freeze -o media/1_cprint_width40.png | null
```

![cprint $sample_text --width 40 --echo](media/1_cprint_width40.png)
