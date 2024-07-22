# nu-goodies

Some of my nushell commands.

## Quickstart

```nushell no-run
> git clone https://github.com/nushell-prophet/nu-goodies
> cd nu-goodies
> use nu-goodies *
```

## cprint

```nu
> let $sample_text = open nu-goodies/lazytests/TheSongoftheFalcon.txt | lines | first 6 | str join (char nl)
> $sample_text
```

```nu no-output
cprint $sample_text --width 40 --echo | freeze -o media/1_cprint_width40.png
```

