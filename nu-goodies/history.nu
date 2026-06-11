alias core_hist = history

use kv

# use in-vd.nu

export def get-last-commands-from-sql [n: int = 1]: nothing -> any {
    if ($nu.history-path | str ends-with 'txt') {
        return (history | last $n | get command | if $n == 1 { get 0 } else { })
    }

    open $nu.history-path
    | query db "select command_line from history order by id desc limit ?" --params [$n]
    | get command_line
    | reverse
    | if $n == 1 { get 0 } else { }
}

# Copy this command to clipboard
export def 'copy-cmd' []: nothing -> nothing {
    let commands = get-last-commands-from-sql 2
        | str trim

    $commands
    | last
    | if $in == 'copy-cmd' {
        $commands | first
    } else { }
    | str replace --regex '\s*\| copy-cmd.*' ''
    | pbcopy
}

# Filter history with regex and convenient flags, add useful columns
export def 'hist' [
    like_filter?: string # a string to search in db
    --regex-filters: list<string> = [] # a regex to search for
    --entries: int = 5000 # A number of last entries to work with
    --all (-a) # Return all the history
    --session (-s) # Show only entries from the current session
    --cwd # Show only entries from the current folder
    --last-x: duration # Duration for the period to check commands
    --not-in-vd (-V) # Disable opening command in visidata
    --all-codes # Output all the commands, no only with 0 code
]: nothing -> any {
    if ($nu.history-path | str ends-with 'txt') {
        print "hist requires SQLite history format"
        return
    }

    # Start building the SQL query
    let sql_query = "
        SELECT command_line as command, start_timestamp / 1000 as start_timestamp, session_id, hostname, cwd,
        duration_ms / 1000000.0 as duration_s, exit_status FROM history WHERE 1=1
    "
        | if $like_filter != null {
            append $" AND command_line LIKE '%($like_filter)%'"
        } else { }
        | append " AND command_line NOT LIKE 'hist %'" # Build where clauses based on parameters Exclude 'hist' commands
        | if $all_codes { } else { append " AND exit_status = 0" } # Only successful commands
        | if $session {
            # Session filter
            append $" AND session_id = (history session)"
        } else { }
        | if $cwd {
            # Folder filter
            append $" AND cwd = '(pwd)'"
        } else { }
        | if $last_x != null {
            # Time filter
            append $" AND start_timestamp > ((date now) - $last_x | into int | $in // 1_000_000)" # ns -> ms, raw start_timestamp column stores milliseconds
        } else { }
        | append ' ORDER BY id DESC'
        | if not ($all or $entries == 0 or $like_filter != null) {
            append $" LIMIT ($entries)"
        } else { }
        | str join

    # Execute the query
    let results = open $nu.history-path | query db $sql_query

    # Apply regex filters in Nushell (SQLite doesn't support all regex features)
    let filtered_results = if $regex_filters == [] {
        $results
    } else {
        $regex_filters
        | reduce --fold $results {|pattern|
            where command =~ $pattern
        }
    }

    # Format timestamps as human readable
    # Convert nanoseconds to seconds and format
    # TODO: check that filtering by options is adjusted by offset too
    let formatted_results = $filtered_results | into datetime --format '%s' --offset (-3) start_timestamp

    # Add pipe count column
    $formatted_results
    | insert pipes {|i|
        # ast --flatten $i.command
        # | where shape == shape_pipe
        $i.command
        | parse --regex '(\s\|)'
        | length
    }
    # Display in visidata or return
    | if $not_in_vd { } else { in-vd history }
}

# Save significant or all current session history entries into a .nu file. If the .nu file already exists, data will be appended.
export def 'hist-to-script' [
    filename?: path
    --dont-open (-O) # Don't open the saved history file in editor
    --up (-u): int = 0 # Set number of last events to save
    --all # Save all history into .nu file
    --directory-hist # Get history for a directory instead of session
]: nothing -> nothing {
    if ($nu.history-path | str ends-with 'txt') {
        print "hist-to-script requires SQLite history format"
        return
    }

    let session = history session

    let filepath = $filename
        | if ($in != null) { } else { $"history($session)" }
        | path parse
        | update extension 'nu'
        | path join

    let hist = open $nu.history-path
        | query db (
            if $directory_hist {
                "SELECT command_line FROM history WHERE cwd = ? ORDER BY id"
            } else {
                "SELECT command_line FROM history WHERE session_id = ? ORDER BY id"
            }
        ) --params [(if $directory_hist { $env.PWD } else { $session })]
        | get command_line
        | str replace --all --regex $';(char nl)\$.*? in-vd' ''
        | drop 1

    let buffer = $hist
        | if $up > 1 {
            last ($up + 1)
        } else if $all { } else {
            where {|i|
                $i =~ '(^(let|def|export) )|#|\b(save|source|mkdir|polars to-csv|polars to-avro|polars to-jsonl|polars to-arrow|polars to-parquet)\b'
            }
        }
        | str join "\n\n"
        | $"\n#($filepath)\n($in)\n#---\n"

    $buffer | save --append $filepath

    if not $dont_open {
        commandline edit --replace $'($env.EDITOR) ($filepath)'
    }
}

# Open nushell commands history in visidata
export def 'in-vd history' []: table -> nothing {
    where command !~ 'in-vd history'
    | to csv
    | vd --save-filetype csv --filetype csv -o -
    | complete
    | get stdout
    | if ($in == null) { return } else { }
    | from csv
    | kv set vd-history --return-to-stdout
    | get command
    | reverse
    | str join $'(char nl)'
    | str replace --regex ';.+?\| in-vd;' ';'
    | commandline edit --replace $in
}

# Helper function to initialize dead_cwds table if it doesn't exist
def 'init-dead-cwds-table' []: nothing -> nothing {
    open $nu.history-path
    | query db "CREATE TABLE IF NOT EXISTS dead_cwds (path TEXT PRIMARY KEY, added_date TEXT DEFAULT CURRENT_TIMESTAMP)"
}

# Helper function to add a dead directory to the table
def 'add-dead-dir' [
    dir: string # Directory to add to dead dirs list
]: nothing -> nothing {
    # Insert new directory if it doesn't exist (parameterized to prevent SQL injection)
    open $nu.history-path
    | query db "INSERT OR IGNORE INTO dead_cwds (path) VALUES (?)" --params [$dir]
}

# Helper function to get all unique directories from command history
# Now with SQL-level filtering against dead_cwds
def 'get-history-dirs' [
    --include-dead (-d) # Include nonexistent directories in the results
]: nothing -> list<string> {
    # Ensure dead_cwds table exists
    init-dead-cwds-table

    if $include_dead {
        # Return all directories without filtering
        open $nu.history-path
        | query db "SELECT DISTINCT(cwd) FROM history ORDER BY id DESC"
        | get cwd
        | compact
    } else {
        # Return only directories that are not in dead_cwds table
        open $nu.history-path
        | query db "SELECT DISTINCT(h.cwd) FROM history h
                   LEFT JOIN dead_cwds d ON h.cwd = d.path
                   WHERE d.path IS NULL
                   ORDER BY h.id DESC"
        | get cwd
        | compact
    }
}

# Scan history directories and rebuild the dead_cwds table with non-existent paths
def 'update-dead-dirs' []: nothing -> list<string> {
    # Get all directories including those already marked as dead
    let all_cwds = get-history-dirs --include-dead

    # Check which directories no longer exist
    let dead_cwds = $all_cwds
        | where {|dir| $dir | path exists | not $in }

    # Clear existing dead_cwds table and insert new values
    # (table already initialized by get-history-dirs above)
    open $nu.history-path
    | query db "DELETE FROM dead_cwds"

    # Insert each dead directory
    $dead_cwds | each {|dir|
        add-dead-dir $dir
    }

    $dead_cwds
}

# Find first existing path from candidates, recording dead ones along the way
def 'find-first-existing' [
    candidates: list<string>
]: nothing -> string {
    $candidates
    | par-each --keep-order {|path|
        if ($path | path exists) {
            $path
        } else {
            add-dead-dir $path
            null
        }
    }
    | compact
    | get 0?
}

# Select a directory path using fuzzy search
def 'select-dir' [
    query: string # The search query
    --interactive (-i) # Force interactive mode
]: nothing -> string {
    let valid_cwds = get-history-dirs | to text

    if ($query | path exists) {
        return $query
    }

    if $interactive {
        return ($valid_cwds | fzf --scheme=path -q $query)
    }

    # Try fuzzy finding first
    let candidates = $valid_cwds | fzf -f $query | lines | first 10
    let existing_path = find-first-existing $candidates

    if ($existing_path | is-empty) {
        # Fall back to interactive
        $valid_cwds | fzf --scheme=path -q $query
    } else {
        $existing_path
    }
}

# Helper function to get open Zellij tab names
def 'zellij-tab-names' []: nothing -> list<string> {
    if ($env.ZELLIJ? | is-empty) { return [] }
    zellij action query-tab-names | lines
}

# Generate regex pattern to match Zellij tab by directory name
# Matches "dirname" or "dirname·2" (indexed duplicates)
def 'zellij-tab-pattern' [dir_name: string]: nothing -> string {
    $"^($dir_name)\(·|$\)"
}

# Handle Zellij tab navigation: create new tab, switch to existing, or rename current.
# Returns true if caller should cd (Zellij renamed tab), false if Zellij handled navigation.
def 'zellij-navigate' [
    path: string # Target directory path
    dir_name: string # Directory name for tab
    --new-tab (-n) # Open in new tab
]: nothing -> bool {
    if ($env.ZELLIJ? | is-empty) { return true }

    if $new_tab {
        # Create new tab with the directory
        zellij action new-tab --layout compact-bar-up --cwd $path --name $dir_name
        return false
    }

    # Check if tab with this name already exists
    let matching_tab = zellij-tab-names
        | where { $in =~ (zellij-tab-pattern $dir_name) }
        | get 0?

    let request: closure = {
        [
            {value: true description: 'switch to existing tab'}
            {value: false description: 'stay here'}
        ]
        | input list 'there is zellij tab already' --display description
        | get value
    }

    if ($matching_tab | is-not-empty) and (do $request) {
        # Switch to existing tab
        zellij action go-to-tab-name $matching_tab
        return false
    }

    # Rename current tab
    zellij action rename-tab $dir_name
    true
}

# Jump to directory from history using fuzzy search
export def --env 'z' [
    query?: string@'completions-cwds' # Fuzzy search query for directory
    --interactive (-i) # Always show interactive picker
    --new-tab (-n) # Open in new Zellij tab
    --update-dead-dirs (-u) # Rebuild nonexistent directories cache
]: nothing -> nothing {
    if ($nu.history-path | str ends-with 'txt') {
        print "z requires SQLite history format"
        return
    }

    # Handle update dead dirs
    if $update_dead_dirs {
        print "Updating dead directories list..."
        update-dead-dirs
        return
    }

    # Get target path - default to interactive mode when no query
    let target_path = select-dir ($query | default "") --interactive=($interactive or ($query | is-empty))

    # Exit if no path was selected
    if ($target_path | is-empty) { return }

    # Expand the path to full format
    let expanded_path = $target_path | path expand

    # Get directory name for tab naming
    let dir_name = $target_path | path split | last

    zellij-navigate $expanded_path $dir_name --new-tab=$new_tab

    cd $expanded_path
}

# Generate completions for z command from history
export def 'completions-cwds' []: nothing -> record {
    if ($nu.history-path | str ends-with 'txt') { return {completions: [] options: {}} }

    # Using SQL-level filtering for completions as well
    init-dead-cwds-table

    let termsize = term size | get columns | $in - 5
    let max_depth = 6

    # Get open Zellij tabs for marking
    let zellij_tabs = zellij-tab-names

    let variants = open $nu.history-path
        | query db "SELECT h.cwd, MAX(h.start_timestamp) as last_timestamp
               FROM history h
               LEFT JOIN dead_cwds d ON h.cwd = d.path
               WHERE d.path IS NULL
               GROUP BY h.cwd
               ORDER BY MAX(h.id) DESC"
        | where cwd != null
        | update cwd {|i|
            do --ignore-errors { $i.cwd | path relative-to $nu.home-dir }
            | match $in {
                null => $i.cwd
                '' => '~'
                $relative_pwd => ([~ $relative_pwd] | path join)
            }
            | if ($in has ' ') { $'\"($in)\"' } else { }
        }
        # Filter by depth - skip paths deeper than max_depth
        | where { $in.cwd | path split | length | $in <= $max_depth }
        # Filter by length
        | where ($it.cwd | str length --grapheme-clusters) < $termsize
        | update last_timestamp {|row|
            let timestamp = $row.last_timestamp | into int | $in / 1000 | into int | into datetime --format '%s' | date humanize

            # Check if a Zellij tab exists for this directory
            let dir_name = $row.cwd | path split | last | str replace '"' ''
            let has_tab = $zellij_tabs | any { $in =~ (zellij-tab-pattern $dir_name) }

            if $has_tab { $"⇆ ($timestamp)" } else { $timestamp }
        }
        | rename value description

    {
        options: {
            case_sensitive: false
            completion_algorithm: fuzzy
            positional: false
            sort: false
        }
        completions: $variants
    }
}
