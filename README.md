# nu-goodies

Some of my nushell commands.

## Quickstart

```nushell no-run
> git clone https://github.com/nushell-prophet/nu-goodies
> cd nu-goodies
> use nu-goodies *
```

## cprint

```nu indent-output
> let $sample_text = open nu-goodies/lazytests/TheSongoftheFalcon.txt | lines | first 6 | str join (char nl)
> $sample_text
//  # The Song of the *Falcon* (excerpt)
//
//  "High up in the mountains, a Snake crawled and lay in a damp gorge, coiled into a knot, staring out at the sea.
//
//  "The sun was shining high in the *sky*, and the mountains were exhaling heat into the *sky*, and the waves were crashing below against the rocks...
```

```nu no-output
cprint $sample_text --width 40 --echo | freeze -o media/1_cprint_width40.png | null
```

![cprint $sample_text --width 40 --echo](media/1_cprint_width40.png)
