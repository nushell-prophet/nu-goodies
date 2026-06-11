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

- `commands.nu` — general-purpose utilities (the largest file, ~980 lines)
- `capture.nu` — terminal capture and screenshot commands
- `cprint.nu` — colorful text printing with wrapping, framing, alignment
- `editors.nu` — editor integration (Helix, fx, VisiData)
- `gradient-screen.nu` — decorative gradient screen fill and `bye`
- `history.nu` — shell history search and manipulation
- `str.nu` — string utilities (`str c`, `str repeat`, `str append`, etc.)
- `macos.nu` — macOS-specific commands (`O`, `ramdisk-create`, `figlet-demo`)
- `update-public-git.nu` — script for syncing patches between private/public repos

### commands.nu

Remaining general-purpose commands (~980 lines). Key categories:

- **Data display**: `bar` (Unicode progress bars), `L` (pipe table to less/bat), `normalize`, `number-format`, `number-col-format`, `side-by-side`
- **File/navigation**: `fs` (interactive file selector), `cd-root`, `find-root`, `mc` (midnight commander-style dual pane)
- **Shell productivity**: `example` (format command + output for sharing), `select-i` (interactive column selector), `fill non-exist`, `replace-in-all-files`
- **Nushell dev**: `nu-test install`, `nu-test launch`, `nu-format`, `significant-digits`
- **Media**: `transcribe`

### capture.nu

Terminal capture and screenshot commands: `copy-out` (clipboard from Zellij scrollback), `wez-to-ansi`, `wez-to-asciicast`, `wez-to-gif`, `wez-to-png`, `zellij-to-png`. Imports from `history.nu` and `str.nu`.

### cprint.nu

Colorful printing with wrapping, framing, alignment, and highlight. Exported as `main` (called as `cprint`). Internal helpers: `wrapit`, `colorit`, `alignit`, `frameit`, `indentit`, `newlineit`, `remove-single-nls`, `width-safe`. Imports from `str.nu`.

### editors.nu

Editor integration: `in-fx` (open in fx JSON viewer), `in-hx` (open in Helix), `in-vd` (open in VisiData). Imports `kv` submodule.

### gradient-screen.nu

Decorative terminal visuals: `gradient-screen` (exported as `main`), `bye` (gradient screen + exit). Imports from `str.nu`.

### history.nu

Shell history commands: `hist` (SQL-based history search with filters), `hist-to-script`, `copy-cmd`, `z` (zoxide wrapper), `in-vd history`, `get-last-commands-from-sql` (shared helper).

### str.nu

String utilities: `str c` (concatenation), `str repeat`, `str append`, `str prepend`, `escape-regex`, `escape-nushell-escapes`, `to-safe-filename`. No imports from other submodules.

### kv/ Submodule

File-backed key-value store (originally by @clipplerblood). Stores values as individual files (`.txt` or `.nuon`) with a `kv.nuon` index. Commands: `ls`, `set`, `get`, `get-file`, `del`, `reset`, `push`, `pop`. Configurable via `$env.kv.path`.

### Inter-module Dependencies

```
str.nu          ← (no deps)
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
