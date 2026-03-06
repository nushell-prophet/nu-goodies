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

`nu-goodies/mod.nu` is the module entry point. It re-exports commands from three sources:
- `commands.nu` - the main collection of utilities (majority of the code)
- `macos.nu` - macOS-specific commands (`O`, `ramdisk-create`, `figlet-demo`)
- `update-public-git.nu` - script for syncing patches between private/public repos

### commands.nu

Single large file (~1500 lines) containing all general-purpose commands. Key command categories:

- **Text formatting**: `cprint` (colorful printing with wrapping, framing, alignment, highlight), plus internal helpers `wrapit`, `colorit`, `alignit`, `frameit`, `indentit`, `newlineit`, `remove-single-nls`, `width-safe`
- **History/shell**: `hist` (SQL-based history search with filters), `hist-to-script`, `copy-cmd`, `copy-out`, `example` (format command + output for sharing)
- **Data display**: `bar` (Unicode progress bars), `L` (pipe table to less/bat), `normalize`, `number-format`, `number-col-format`, `side-by-side`
- **File/navigation**: `fs` (interactive file selector), `z` (zoxide wrapper), `cd-root`, `find-root`, `mc` (midnight commander-style dual pane)
- **Editor integration**: `in-hx` (open in Helix), `in-fx` (open in fx JSON viewer), `in-vd` (open in Visidata)
- **Text utilities**: `str c` (string concatenation), `fill non-exist` (fill missing table columns), `select-i` (interactive column selector)
- **Terminal visuals**: `gradient-screen`, `bye` (gradient screen + exit)
- **Media**: `transcribe`, `wez-to-gif`, `wez-to-png`, `wez-to-ansi`, `wez-to-asciicast`, `zellij-to-png`

### kv/ Submodule

File-backed key-value store (originally by @clipplerblood). Stores values as individual files (`.txt` or `.nuon`) with a `kv.nuon` index. Commands: `ls`, `set`, `get`, `get-file`, `del`, `reset`, `push`, `pop`. Configurable via `$env.kv.path`.

### History Access Pattern

Commands that access shell history use a helper `get-last-commands-from-sql` which queries the SQLite history file directly via `open $nu.history-path | query db`. The codebase guards against plain-text history format and expects SQLite format for full functionality.

## Conventions

- Commands use Nushell's typed input/output signatures (e.g., `]: string -> string {`)
- Internal helpers are non-exported `def` commands; public API commands use `export def`
- `mod.nu` controls the public API by selectively importing from `commands.nu` - commented-out entries are intentionally hidden
- The `str c` command (string concatenation) is used extensively instead of string interpolation for building strings
- `par-each` is preferred over `each` for parallelizable operations
