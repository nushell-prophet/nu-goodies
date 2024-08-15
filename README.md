# nu-goodies

Some of my nushell commands.

## Quickstart

```nushell no-run
> git clone https://github.com/nushell-prophet/nu-goodies
> cd nu-goodies
> use nu-goodies *
```

## cprint

`cprint` provides enhanced formatting for long text messages in your scripts. It supports colorful output, text highlighting, framing, and various text formatting options for improved readability and presentation.


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
  -c, --color <CompleterWrapper(String, 704)> - color to use for the main text (default: 'default')
  -H, --highlight_color <CompleterWrapper(String, 704)> - color to use for highlighting text enclosed in asterisks (default: 'green_bold')
  -r, --frame_color <CompleterWrapper(String, 704)> - color to use for frame (default: 'dark_gray')
  -f, --frame <String> - symbol (or a string) to frame a text (default: '')
  -b, --lines_before <Int> - number of new lines before a text (default: 0)
  -a, --lines_after <Int> - number of new lines after a text (default: 1)
  -e, --echo - echo text string instead of printing
  --keep_single_breaks - don't remove single line breaks
  -w, --width <Int> - the total width of text to wrap it (default: 80)
  -i, --indent <Int> - indent output by number of spaces (default: 0)
  --align <String> - alignment of text (default: 'left')

Parameters:
  text <string>: text to format, if omitted stdin will be used (optional)

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ string │
  │ string  │ string │
  ╰──input──┴─output─╯
```

### Examples

```nu
let $sample_text = r##'# The Song of the *Falcon* (excerpt)

"High up in the mountains, a Snake crawled and lay in a damp gorge, coiled into a knot, staring out at the sea.

"The sun was shining high in the *sky*, and the mountains were exhaling heat into the *sky*, and the waves were crashing below against the rocks...
'##
```

Let's wrap the long text to 40 symbols

```nu no-output
cprint $sample_text --width 40 --echo --highlight_color yellow
| freeze -o media/1_cprint_width40.png --theme average | null
```

![cprint $sample_text --width 40 --echo](media/1_cprint_width40.png)

`cprint` can be used inside of code to automatically concatenate texts delimited by single new lines. By default, all space characters from line beginnings are removed.

```nu
def example_command_with_formatted_code [] {
    # some code
    if true {
        cprint "Here we have a really long line that we want to show
            to the final user, yet we don't want to spoil our code formatting.

            So we make a new paragraph with a double new line, and leave single
            new lines to be concatenated automatically by `cprint`.

            This behaviour can be disabled with the `--keep_single_breaks` flag."
    }
}

# and we execute the command to show how cprint works.
example_command_with_formatted_code
```

Output:

```
Here we have a really long line that we want to show to the final user, yet we
don't want to spoil our code formatting.

So we make a new paragraph with a double new line, and leave single new lines to
be concatenated automatically by `cprint`.

This behaviour can be disabled with the `--keep_single_breaks` flag.
```

Text can be indented and aligned

```nu
cprint $sample_text --indent 5 --width 45 --align center --echo --highlight_color yellow
| freeze -o media/2_cprint_indent_align.png --theme average | null
```

![cprint $sample_text --indent 5 --width 45 --align center --echo --highlight_color yellow](media/2_cprint_indent_align.png)
