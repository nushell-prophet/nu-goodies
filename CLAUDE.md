# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`nu-goodies` is a Nushell module providing a collection of utility commands for text formatting, data wrangling, shell productivity, and macOS integration. It is written entirely in Nushell (`.nu` files).

## Usage

```nushell
use nu-goodies *
```

Load the module to make all exported commands available. Individual submodules can also be loaded:
- `use nu-goodies/kv` - key-value store

## Testing

Tests use `numd` (Nushell-native markdown processor). Test files are in `nu-goodies/lazytests/` as `.nu` markdown files. There is no standard test runner; tests are executed by running the `.nu` files through `numd`.

## Code Formatting

Use [Topiary](https://github.com/tweag/topiary) for formatting `.nu` files.

## Architecture

### Module Entry Point

`nu-goodies/mod.nu` is the module entry point. It re-exports commands from dedicated submodules:

- `commands.nu` — general-purpose utilities (the largest file)
- `arrange.nu` — terminal window/pane layout: `screen center`, `screen splash`, `tile-right`/`tile-left`/`tile-down`/`tile-up`
- `capture.nu` — terminal capture, screenshot, and ANSI→PNG rendering commands
- `cprint.nu` — colorful text printing with wrapping, framing, alignment
- `editors.nu` — editor integration (Helix, fx, VisiData)
- `gradient-screen.nu` — decorative gradient screen fill and `bye`
- `history.nu` — shell history search and manipulation
- `str.nu` — string utilities (`str c`, `str repeat`, `str append`, etc.)
- `macos.nu` — macOS-specific commands (`O`, `ramdisk-create`, `figlet-demo`)
- `update-public-git.nu` — script for syncing patches between private/public repos

### commands.nu

Remaining general-purpose commands. Key categories (not exhaustive — check `mod.nu` for the full public list):

- **Data display**: `bar` (Unicode progress bars), `L` (pipe table to less/bat), `normalize`, `number-format`, `number-col-format`
- **File/navigation**: `fs` (interactive file selector), `cd-root`, `find-root`, `mc` (midnight commander-style dual pane), `ln-for-preview`, `mv-update-links`, `ls-git-modified-date`
- **Shell productivity**: `example` (format command + output for sharing), `select-i` (interactive column selector), `fill non-exist`, `replace-in-all-files`, `fzf-preview`, `tarq`, `to-temp-file`, `rename-tab`
- **Nushell dev**: `nu-test install`, `nu-test launch`, `nu-format`, `cargo-updates`, `format profile`
- **Media**: `transcribe`

### capture.nu

Terminal capture, screenshot, and ANSI→PNG rendering. Exports: `ansi-to-png`, `install-deps`, `copy-out` (clipboard from Zellij scrollback), `in-pane`, `delete-prompts`, `wez-to-ansi`, `wez-to-asciicast`, `wez-to-gif`, `wez-to-png`, `zellij-to-png`. Imports from `history.nu` and `str.nu`.

`ansi-to-png` is the core renderer the show visuals pipe into (`npshow` covers, demo captures): it takes ANSI-colored text on stdin and rasterizes it via `ansisvg` → `rsvg-convert` (librsvg). Key flags — `out?` (auto-picks the next free `img<N>.png` in cwd), `--font-size 50`, `--font-name 'ZedMono NF Extd'` (the Extended stretch wezterm uses, so box-drawing/logo glyphs render right), `--line-height`, `--width` (ansisvg column width; wider than content = right-pad), `--background '#000000'` (matches the cozy sandbox), `--colorscheme 'Wez'` (resolves palette-dependent ANSI codes with wezterm's palette), `--recolor` (bold-brighten swaps ansisvg can't do), `--show` (preview with chafa). The `# Why:` comments on each flag record the palette-matching reasoning — keep them. `install-deps` is the idempotent provisioner for its four dependencies: ansisvg (via `go install`, symlinked into the brew prefix), librsvg, chafa, and the ZedMono Nerd Font cask.

### arrange.nu

Terminal window/pane layout and centering. Exports: `screen center` (center content in the terminal), `screen splash`, and the `tile-*` family (`tile-right`, `tile-left`, `tile-down`, `tile-up`). No imports from other submodules.

### cprint.nu

Colorful printing with wrapping, framing, alignment, and highlight. Exported as `main` (called as `cprint`). Internal helpers: `wrapit`, `colorit`, `alignit`, `frameit`, `indentit`, `newlineit`, `remove-single-nls`, `width-safe`. Imports from `str.nu`.

### editors.nu

Editor integration: `in-fx` (open in fx JSON viewer), `in-hx` (open in Helix), `in-vd` (open in VisiData). Imports `kv` submodule.

### gradient-screen.nu

Decorative terminal visuals: `gradient-screen` (exported as `main`), `bye` (gradient screen + exit). Imports from `str.nu`.

### history.nu

Shell history commands: `hist` (SQL-based history search with filters), `hist-to-script`, `copy-cmd`, `z` (zoxide wrapper), `in-vd history`, `get-last-commands-from-sql` (shared helper).

### str.nu

String utilities. Public exports: `str c` (concatenation), `str to-raw-string`, `to-safe-filename`. The file also defines `str repeat`, `str append`, `str prepend`, `escape-regex`, `escape-nushell-escapes`, but these are commented out in `mod.nu` (intentionally hidden). No imports from other submodules.

### kv/ Submodule

File-backed key-value store (originally by @clipplerblood). Stores values as individual files (`.txt` or `.nuon`) with a `kv.nuon` index. Commands: `ls`, `set`, `get`, `get-file`, `del`, `reset`, `push`, `pop`. Configurable via `$env.kv.path`.

### Inter-module Dependencies

```
str.nu          ← (no deps)
arrange.nu      ← (no deps)
cprint.nu       ← str.nu
gradient-screen.nu ← str.nu
history.nu      ← (no deps)
editors.nu      ← kv/
capture.nu      ← str.nu, history.nu
commands.nu     ← str.nu, history.nu
```

### History Access Pattern

Commands that access shell history use a helper `get-last-commands-from-sql` which queries the SQLite history file directly via `open $nu.history-path | query db`. The codebase guards against plain-text history format and expects SQLite format for full functionality.

## Conventions

- Commands use Nushell's typed input/output signatures (e.g., `]: string -> string {`)
- Internal helpers are non-exported `def` commands; public API commands use `export def`
- `mod.nu` controls the public API by selectively importing from each submodule - commented-out entries are intentionally hidden
- When extracting a command to a new file, the command named the same as the module file must be renamed to `main` (Nushell restriction)
- The `str c` command (string concatenation) is used extensively instead of string interpolation for building strings
- `par-each` is preferred over `each` for parallelizable operations
