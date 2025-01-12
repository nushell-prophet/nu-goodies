```nu
 use nu-goodies/commands.nu *
```

# L

```nu
> L --help | numd parse-help
// Description:
//   ##file L.nu
//   open table in Less
//
// Usage:
//   > L {flags}
//
// Flags:
//   -a, --abbreviated <int> (default: 1000)
//   -b, --bat: use bat instead of less
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# O

```nu
> O --help | numd parse-help
// Description:
//   Open a file in the specified macOS application or reveal it in Finder (--app flag supports completions)
//   > O O.nu --app "Sublime Text"
//
// Usage:
//   > O {flags} (filepath)
//
// Flags:
//   -a, --app <string>: app to open at (default: 'Snagit 2022.app')
//   -r, --reveal: reveal app in finder
//
// Parameters:
//   filepath <path> (optional)
//
// Input/output types:
//   ╭─#─┬──input──┬─output──╮
//   │ 0 │ string  │ nothing │
//   │ 1 │ nothing │ nothing │
//   ╰─#─┴──input──┴─output──╯
```

# bar

```nu
> bar --help | numd parse-help
// Description:
//   construct bars based of a given percentage from a given width (5 is default)
//
// Usage:
//   > bar {flags} <percentage>
//
// Flags:
//   -b, --background <string> (default: 'default')
//   -f, --foreground <string> (default: 'default')
//   -p, --progress: output the result using 'print -n'
//   -w, --width <int> (default: 5)
//
// Parameters:
//   percentage <float>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
//
// Examples:
//   https://github.com/nushell/nu_scripts/blob/bar/sourced/progress_bar/bar.nu
//   > bar 0.2
//   █
//   > bar 0.71
//   ███▌
```

# bye

```nu
> bye --help | numd parse-help
// Usage:
//   > bye {flags} ...(strings)
//
// Flags:
//   --no_date: don't append date
//   -n: don't quit
//
// Parameters:
//   ...strings <string>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# cb

```nu
> cb --help | numd parse-help
// Description:
//   ##file cb.nu
//   shortcut for pbpaste and pbcopy. But is it needed?
//
// Usage:
//   > cb {flags}
//
// Flags:
//   --paste
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# center

```nu
> center --help | numd parse-help
// Description:
//   ##file center.nu
//
// Usage:
//   > center {flags}
//
// Flags:
//   --factor <int> (default: 1)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# copy-cmd

```nu
> copy-cmd --help | numd parse-help
// Description:
//   ##file copy-cmd.nu
//   copy this command to clipboard
//
// Usage:
//   > copy-cmd
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# cprint

```nu
> cprint --help | numd parse-help
// Description:
//   ##file cprint.nu
//   Print a string colorfully with bells and whistles
//
// Usage:
//   > cprint {flags} (text)
//
// Flags:
//   -c, --color <string>: color to use for the cprint text (default: 'default')
//   -H, --highlight_color <string>: color to use for highlighting text enclosed in asterisks (default: 'green_bold')
//   -r, --frame_color <string>: color to use for frame (default: 'dark_gray')
//   -f, --frame <string>: symbol (or a string) to frame a text (default: '')
//   -b, --lines_before <int>: number of new lines before a text (default: 0)
//   -a, --lines_after <int>: number of new lines after a text (default: 1)
//   -e, --echo: echo text string instead of printing
//   --keep_single_breaks: don't remove single line breaks
//   -w, --width <int>: the total width of text to wrap it (default: 80)
//   -i, --indent <int>: indent output by number of spaces (default: 0)
//   --align <string>: alignment of text (default: 'left')
//
// Parameters:
//   text <string>: text to format, if omitted stdin will be used (optional)
//
// Input/output types:
//   ╭─#─┬──input──┬─output──╮
//   │ 0 │ string  │ nothing │
//   │ 1 │ nothing │ nothing │
//   │ 2 │ nothing │ string  │
//   │ 3 │ string  │ string  │
//   ╰─#─┴──input──┴─output──╯
```

# width-safe

```nu
> width-safe --help | numd parse-help
// Usage:
//   > width-safe <$width> <$indent>
//
// Parameters:
//   $width <any>
//   $indent <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# wrapit

```nu
> wrapit --help | numd parse-help
// Usage:
//   > wrapit <$keep_single_breaks> <$width_safe> <$indent>
//
// Parameters:
//   $keep_single_breaks <any>
//   $width_safe <any>
//   $indent <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# remove_single_nls

```nu
> remove_single_nls --help | numd parse-help
// Usage:
//   > remove_single_nls
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# newlineit

```nu
> newlineit --help | numd parse-help
// Usage:
//   > newlineit <$before> <$after>
//
// Parameters:
//   $before <any>
//   $after <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# frameit

```nu
> frameit --help | numd parse-help
// Usage:
//   > frameit <$width_safe> <$frame> <$frame_color>
//
// Parameters:
//   $width_safe <any>
//   $frame <any>
//   $frame_color <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# colorit

```nu
> colorit --help | numd parse-help
// Usage:
//   > colorit <$highlight_color> <$color>
//
// Parameters:
//   $highlight_color <any>
//   $color <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# alignit

```nu
> alignit --help | numd parse-help
// Usage:
//   > alignit <$alignment> <$width_safe>
//
// Parameters:
//   $alignment <string>
//   $width_safe <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# indentit

```nu
> indentit --help | numd parse-help
// Usage:
//   > indentit <$indent>
//
// Parameters:
//   $indent <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# dfr enumerate

```nu
> dfr enumerate --help | numd parse-help
// Description:
//   ##file dfr enumerate.nu
//
// Usage:
//   > dfr enumerate (n)
//
// Parameters:
//   n <int>:  (optional, default: 3)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# example

```nu
> example --help | numd parse-help
// Description:
//   ##file example.nu
//   output a command from a pipe where `example` used, and truncate the output table
//
// Usage:
//   > example {flags}
//
// Flags:
//   -C, --dont_copy
//   -H, --dont_comment
//   -i, --indentation_spaces <int> (default: 1)
//   --abbreviated <int> (default: 10)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
//
// Examples:
//   > ls nu-goodies | first 3 | reject modified | example
//   ╭───────────name───────────┬─type─┬──size──╮
//   │ nu-goodies/str.nu        │ file │ 1.4 KB │
//   │ nu-goodies/cb.nu         │ file │  170 B │
//   │ nu-goodies/abbreviate.nu │ file │  898 B │
//   ╰───────────name───────────┴─type─┴──size──╯
```

# fill non-exist

```nu
> fill non-exist --help | numd parse-help
// Description:
//   ##file fill non-exist.nu
//   fill missing columns for each row
//
// Usage:
//   > fill non-exist (value_to_replace)
//
// Parameters:
//   value_to_replace <any>:  (optional, default: '')
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
//
// Examples:
//   this is how empty columns are present
//   > [{a: 1} {b: 2}] | to nuon
//   [{a: 1}, {b: 2}]
//
//   > [{a: 1} {b: 2}] | fill non-exist | to nuon
//   [{a: 1, b: ""}, {b: 2, a: ""}]
```

# format profile

```nu
> format profile --help | numd parse-help
// Description:
//   format `debug profile` output
//
// Usage:
//   > format profile
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
//
// Examples:
//   > debug profile {pin-text cyber} --max-depth 7 --spans | format profile | null
```

# gradient-screen

```nu
> gradient-screen --help | numd parse-help
// Description:
//   ##file gradient-screen.nu
//   fill screen with repeated texts from arguments or $env.gradient-screen.texts with random color gradient
//
// Usage:
//   > gradient-screen {flags} ...(strings)
//
// Flags:
//   --no_date: don't append date
//   --echo
//   --rows <int>
//
// Parameters:
//   ...strings <string>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# hist

```nu
> hist --help | numd parse-help
// Description:
//   Filter history with regex and convenient flags, add useful columns
//
// Usage:
//   > hist {flags} ...(query)
//
// Flags:
//   --entries <int>: a number of last entries to work with (default: 5000)
//   -a, --all: return all the history
//   -s, --session: show only entries from the current session
//   --folder: show only entries from the current folder
//   --last_x <duration>: duration for the period to check commands
//   -V, --not_in_vd: disable opening command in visidata
//
// Parameters:
//   ...query <string>: a regex to search for
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# hs

```nu
> hs --help | numd parse-help
// Description:
//   ##file hs.nu
//   Save significant or all current session history entries into a .nu file. If the .nu file already exists, data will be appended.
//
// Usage:
//   > hs {flags} (filename)
//
// Flags:
//   --dir <string>: where to save history file
//   -O, --dont_open: don't open the save history file in editor
//   -u, --up <int>: set number of last events to save (default: 0)
//   --all: Save all history into .nu file
//   --directory_hist: get history for a directory instead of session
//
// Parameters:
//   filename <any> (optional)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# in-fx

```nu
> in-fx --help | numd parse-help
// Description:
//
// Examples:
//   fx 35.0.0
//   Terminal JSON viewer
//
//   Usage
//   fx data.json
//   fx data.json .field
//   curl ... | fx
//
//   Flags
//   -h, --help            print help
//   -v, --version         print version
//   --themes              print themes
//   --comp <shell>        print completion script
//   -r, --raw             treat input as a raw string
//   -s, --slurp           read all inputs into an array
//   --yaml                parse input as YAML
//
//   Key Bindings
//   q, ctrl+c, esc        exit program
//   pgdown, space, f      page down
//   pgup, b               page up
//   u, ctrl+u             half page up
//   d, ctrl+d             half page down
//   g, home               goto top
//   G, end                goto bottom
//   down, j               down
//   up, k                 up
//   ?                     show help
//   right, l, enter       expand
//   left, h, backspace    collapse
//   L, shift+right        expand recursively
//   H, shift+left         collapse recursively
//   e                     expand all
//   E                     collapse all
//   1-9                   collapse to nth level
//   J, shift+down         next sibling
//   K, shift+up           previous sibling
//   z                     toggle strings wrap
//   y                     yank/copy
//   /                     search regexp
//   n                     next search result
//   N                     prev search result
//   p                     preview
//   P                     print
//   .                     dig
//
//   More info
//   [https://fx.wtf]
```

# in-hx

```nu
> in-hx --help | numd parse-help
// Description:
//   ##file in-hx.nu
//   open piped-in results in hx, output back the saved file
//
// Usage:
//   > in-hx {flags}
//
// Flags:
//   -p, --path: output path of the file
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# in-vd

```nu
> in-vd --help | numd parse-help
// Description:
//   Open data in VisiData🔥
//
// Examples:
//   > history | in-vd
//
//   The suitable format is detected automatically.
//   If VisiData produces STDOUT, it will be assigned to $env.vd_temp.n
//
// Usage:
//   > in-vd {flags}
//
// Subcommands:
//   in-vd history (custom) - Open nushell commands history in visidata
//
// Flags:
//   -j, --json: force to use msgpack for piping data in-vd
//   -c, --csv: force to use csv for piping data in-vd
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# in-vd history

```nu
> in-vd history --help | numd parse-help
// Description:
//   Open nushell commands history in visidata
//
// Usage:
//   > in-vd history
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# mc

```nu
> mc --help | numd parse-help
// Description:
//   ##file mc.nu
//   open midnight commander, cd to the last folder
//
// Usage:
//   > mc (path1) (path2)
//
// Parameters:
//   path1 <path> (optional)
//   path2 <path> (optional)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# md

```nu
> md --help | numd parse-help
// Description:
//   ##file md.nu
//   makedir and cd into it
//
// Usage:
//   > md {flags} <target_dir>
//
// Flags:
//   -d: use standard directory
//   --dest_dir <path> (default: '/Users/user/temp')
//
// Parameters:
//   target_dir <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# mv1

```nu
> mv1 --help | numd parse-help
// Description:
//   ##file mv1.nu
//   toggle suffix `_back` for a file
//
// Usage:
//   > mv1 <file>
//
// Parameters:
//   file <path>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# mygit log

```nu
> mygit log --help | numd parse-help
// Description:
//   ##file mygit log.nu
//   commit current version of dot files and apps settings
//
// Usage:
//   > mygit log {flags}
//
// Flags:
//   -m, --message <string>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# backup-history

```nu
> backup-history --help | numd parse-help
// Usage:
//   > backup-history
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# normalize

```nu
> normalize --help | numd parse-help
// Description:
//   ##file normalize.nu
//   normalize values in given columns
//
// Usage:
//   > normalize {flags} ...(column_names)
//
// Flags:
//   --suffix <string> (default: '_norm')
//
// Parameters:
//   ...column_names <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
//
// Examples:
//   > [[a b]; [1 2] [3 4] [a null]] | normalize a b
//   ╭─a─┬─b─┬a_norm┬b_norm╮
//   │ 1 │ 2 │ 0.33 │ 0.50 │
//   │ 3 │ 4 │    1 │    1 │
//   │ a │   │ a    │      │
//   ╰───┴───┴──────┴──────╯
```

# install

```nu
> install --help | numd parse-help
// Description:
//   ##file nu-test.nu
//   install nushell or polars from the HEAD or the specified PR
//
// Usage:
//   > install {flags}
//
// Flags:
//   --nushell: update nushell only
//   --polars: update polars plugin only
//   --nushell-repo-path <path> (default: '/Users/user/git/nushell/')
//   --cargo-test-path <path> (default: '/Users/user/.cargo_test/')
//   --plugin-config <path> (default: '/Users/user/.test_config/nushell/polars_test.msgpackz')
//   --pr <string>: a pr to checkout like ayax79:polars_pivot
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# launch

```nu
> launch --help | numd parse-help
// Usage:
//   > launch {flags}
//
// Flags:
//   --no-plugin
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# download-nushell-nightly

```nu
> download-nushell-nightly --help | numd parse-help
// Usage:
//   > download-nushell-nightly {flags}
//
// Flags:
//   -a, --arch <string>: archicture as specified in nushell/nightly repo (default: 'aarch64-apple-darwin')
//   -e, --ext <string>: extension, including the leading dot (e.g. '.tar.gz') (default: '.tar.gz')
//   -d, --destination_dir <directory>: destination directory in which to save the download (default: '/Users/user/temp/nu-nightly')
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# launch-downloaded

```nu
> launch-downloaded --help | numd parse-help
// Usage:
//   > launch-downloaded
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# number-col-format

```nu
> number-col-format --help | numd parse-help
// Description:
//   Format number column in a table using number-format
//
// Usage:
//   > number-col-format {flags} <column_name>
//
// Flags:
//   -t, --thousands_delim <string>: Thousands delimiter: number-format 1000 -t ': 1'000 (default: '_')
//   -d, --decimals <int>: Number of digits after decimal delimiter: number-format 1000.1234 -d 2: 1000.12 (default: 0)
//   -D, --denom <string>: Denom `--denom "Wt": number-format 1000 --denom 'Wt': 1000Wt (default: '')
//   --significant_digits <int>: The number of first digits to display, others will become 0 (default: 0)
//
// Parameters:
//   column_name <string>: A column name to format
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
//
// Examples:
//   > [[a]; [123456.678] [2345.8900]] | number-col-format a --denom wt --decimals 2 --significant_digits 3
//   ╭──────a───────╮
//   │ 123_000.00wt │
//   │   2_340.00wt │
//   ╰──────────────╯
```

# number-format

```nu
> number-format --help | numd parse-help
// Description:
//   Format big numbers nicely
//
// Usage:
//   > number-format {flags} (num)
//
// Flags:
//   -t, --thousands_delim <string>: Thousands delimiter (default: '_')
//   -i, --integers <int>: Length of padding whole-part digits (default: 0)
//   --significant_digits <int>: The number of first digits to display, others will become 0 (default: 0)
//   -d, --decimals <int>: Number of digits after decimal delimiter (default: 0)
//   -D, --denom <string>: Denom (default: '')
//   --color <string> (default: 'green')
//
// Parameters:
//   num <any>: Number to format (optional)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
//
// Examples:
//   > number-format 1000 --thousands_delim "'"
//   1'000
//
//   > number-format 123 --integers 6
//   123
//
//   > number-format 1000.1234 --decimals 2
//   1_000.12
//
//   > number-format 1000 --denom 'Wt'
//   1_000Wt
```

# orbita

```nu
> orbita --help | numd parse-help
// Description:
//   ##file orbita.nu
//
// Usage:
//   > orbita
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# print-and-pass

```nu
> print-and-pass --help | numd parse-help
// Description:
//   ##file print-and-pass.nu
//   An alternative to `inspect` that doesn't break debugging output
//
// Usage:
//   > print-and-pass (callback)
//
// Parameters:
//   callback <closure()> (optional)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# ramdisk-create

```nu
> ramdisk-create --help | numd parse-help
// Description:
//   ##file ramdisk-create.nu
//   Create ramdisk in MacOS
//
// Usage:
//   > ramdisk-create (size)
//
// Parameters:
//   size <filesize>:  (optional, default: 3.9 GiB)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# select-i

```nu
> select-i --help | numd parse-help
// Description:
//   interactively select columns from a table
//
// Usage:
//   > select-i
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# side-by-side

```nu
> side-by-side --help | numd parse-help
// Description:
//   ##file side-by-side.nu
//
// Usage:
//   > side-by-side {flags} <r>
//
// Flags:
//   --delimiter <string>: delimiter between left and right (default: ' ')
//   --collapse: use collapsed table representation
//   --l_header <string>
//   --r_header <string>
//
// Parameters:
//   r <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# str repeat

```nu
> str repeat --help | numd parse-help
// Usage:
//   > str repeat <$n>
//
// Parameters:
//   $n <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# str append

```nu
> str append --help | numd parse-help
// Usage:
//   > str append {flags} ...(text)
//
// Flags:
//   -s, --space
//   -2, --2space
//   -n, --new-line
//   -t, --tab
//   -c, --concatenator <string>: input and rest concatenator (default: '')
//   --rest_el <string>: rest elements concatenator (default: ' ')
//
// Parameters:
//   ...text <string>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# str prepend

```nu
> str prepend --help | numd parse-help
// Usage:
//   > str prepend {flags} ...(text)
//
// Flags:
//   -s, --space
//   -2, --2space
//   -n, --new-line
//   -t, --tab
//   -c, --concatenator <string>: input and rest concatenator (default: '')
//   --rest_el <string>: rest elements concatenator (default: ' ')
//
// Parameters:
//   ...text <string>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# indent

```nu
> indent --help | numd parse-help
// Usage:
//   > indent
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# dedent

```nu
> dedent --help | numd parse-help
// Usage:
//   > dedent
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# escape-regex

```nu
> escape-regex --help | numd parse-help
// Usage:
//   > escape-regex
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# escape-escapes

```nu
> escape-escapes --help | numd parse-help
// Usage:
//   > escape-escapes
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# testcd

```nu
> testcd --help | numd parse-help
// Description:
//   ##file testcd.nu
//
// Usage:
//   > testcd <destination>
//
// Parameters:
//   destination <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# to-temp-file

```nu
> to-temp-file --help | numd parse-help
// Description:
//   <() from bash.
//
// Usage:
//   > to-temp-file (content)
//
// Parameters:
//   content <any>: Commands used to generate the content of the file. (optional)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
//
// Examples:
//   The closure parameter is used, or the string stdin. Can take both applying
//   the stdin first. If no stdin is used closure takes no argument & the output is
//   used as the file content. If there is stdin closure takes the file name as an
//   argument & operates on it.
```

# transcribe

```nu
> transcribe --help | numd parse-help
// Description:
//   ##file transcribe.nu
//
// Usage:
//   > transcribe <file>
//
// Parameters:
//   file <path>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# wez-to-ansi

```nu
> wez-to-ansi --help | numd parse-help
// Description:
//   ##file wez-to-ansi.nu
//
// Usage:
//   > wez-to-ansi {flags} ($n_last_commands)
//
// Flags:
//   --regex <string>: Regex to separate prompts from outputs. Default is ''. (default: '^>')
//   --lines_before_top_of_term <int>: Lines from top of scrollback in Wezterm to capture. (default: 100)
//   --min_term_width <int> (default: 0)
//
// Parameters:
//   $n_last_commands <int>: Number of recent commands (and outputs) to capture. (optional, default: 2)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# wez-to-gif

```nu
> wez-to-gif --help | numd parse-help
// Description:
//   ##file wez-to-gif.nu
//   wez-to-gif
//
// Usage:
//   > wez-to-gif {flags} (command)
//
// Flags:
//   --filename <path>
//   --font-family <string> (default: 'Iosevka Extended')
//   --font-size <int> (default: 20)
//   --ascinema: copy ascinema here too
//
// Parameters:
//   command <string>:  (optional, default: '')
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# wez-to-png

```nu
> wez-to-png --help | numd parse-help
// Description:
//   capture wezterm scrollback, split by prompts, output chosen ones to an image file
//
// Usage:
//   > wez-to-png {flags} ($n_last_commands)
//
// Flags:
//   --output_path <path>: Path for saving output images. (default: '')
//
// Parameters:
//   $n_last_commands <int>: Number of recent commands (and outputs) to capture. (optional, default: 2)
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# z

```nu
> z --help | numd parse-help
// Description:
//   ##file z.nu
//
// Usage:
//   > z {flags} ...(rest)
//
// Flags:
//   -i, --interactive
//   -n, --new-tab
//
// Parameters:
//   ...rest <string>
//
// Input/output types:
//   ╭─#─┬──input──┬─output──╮
//   │ 0 │ nothing │ nothing │
//   ╰─#─┴──input──┴─output──╯
```

# replace-in-all-files

```nu
> replace-in-all-files --help | numd parse-help
// Usage:
//   > replace-in-all-files {flags} <$find> <$replace>
//
// Flags:
//   --quiet: don't outuput stats
//   --no-git-check
//
// Parameters:
//   $find <any>
//   $replace <any>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```

# check-clean-working-tree

```nu
> check-clean-working-tree --help | numd parse-help
// Usage:
//   > check-clean-working-tree <$module_path>
//
// Parameters:
//   $module_path <path>
//
// Input/output types:
//   ╭─#─┬─input─┬─output─╮
//   │ 0 │ any   │ any    │
//   ╰─#─┴─input─┴─output─╯
```
