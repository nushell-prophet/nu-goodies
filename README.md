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
cprint --help | numd parse-help
```

Output:

```
Description:
  Print a string colorfully with bells and whistles

Usage:
  > main {flags} (text)

Flags:
  -c, --color <String> - color to use for the main text (default: 'default')
  -h, --highlight_color <String> - color to use for highlighting text enclosed in asterisks (default: 'green_bold')
  -r, --frame_color <String> - color to use for frame (default: 'dark_gray')
  -f, --frame <String> - symbol (or a string) to frame a text (default: '')
  -b, --lines_before <Int> - number of new lines before a text (default: 0)
  -a, --lines_after <Int> - number of new lines after a text (default: 1)
  -e, --echo - echo text string instead of printing
  --keep_single_breaks - don't remove single line breaks
  -w, --width <Int> - the total width of text to wrap it (default: 80)
  -i, --indent <Int> - indent output by number of spaces (default: 0)
  --alignment <String> - aligment of text (default: 'left')

Parameters:
  text <string>: text to format, if ommited stdin will be used (optional)

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ string │
  │ string  │ string │
  ╰──input──┴─output─╯
```

![](media/0_cprint_help.png)

```nu no-output
let $sample_text = r##'# The Song of the *Falcon* (excerpt)

"High up in the mountains, a Snake crawled and lay in a damp gorge, coiled into a knot, staring out at the sea.

"The sun was shining high in the *sky*, and the mountains were exhaling heat into the *sky*, and the waves were crashing below against the rocks...
'##
```

```nu no-output
cprint $sample_text --width 40 --echo | freeze -o media/1_cprint_width40.png | null
```

![cprint $sample_text --width 40 --echo](media/1_cprint_width40.png)
