# hist-sql alias
export def 'hist' [
    ...query: string # a regex to search for
    --entries: int = 5000 # a number of last entries to work with
    --all (-a) # return all the history
    --session (-s) # show only entries from the current session
    --folder # show only entries from the current folder
    --last_x: duration # duration for the period to check commands
    --not_in_vd (-V) # disable opening command in visidata
] {
    # Get path to the history database
    let db_path = $nu.history-path

    # Start building the SQL query
    mut sql_query = "SELECT command_line as command, start_timestamp, session_id, hostname, cwd,
                    duration_ms / 1000000.0 as duration_s, exit_status FROM history WHERE 1=1"

    # Build where clauses based on parameters
    # Exclude 'hist' commands
    $sql_query = $sql_query + " AND command_line NOT LIKE 'hist %'"

    # Only successful commands
    $sql_query = $sql_query + " AND exit_status = 0"

    # Session filter
    if $session {
        let current_session = (history session | into string)
        $sql_query = $sql_query + " AND session_id = " + $current_session
    }

    # Folder filter
    if $folder {
        let current_dir = (pwd | into string)
        $sql_query = $sql_query + " AND cwd = '" + $current_dir + "'"
    }

    # Time filter
    if $last_x != null {
        let timestamp = ((date now) - $last_x | format date '%s') | into int
        $sql_query = $sql_query + " AND start_timestamp > " + $timestamp + "000000000" # Convert to nanoseconds
    }

    # Query regex filters
    let regex_filters = $query

    # Order by and limit
    $sql_query = $sql_query + " ORDER BY start_timestamp DESC"

    # Apply limit if not --all
    if not ($all or $entries == 0) {
        $sql_query = $sql_query + " LIMIT " + $'($entries)'
    }

    # Execute the query
    let results = (^sqlite3 -json $db_path $sql_query | from json)

    # Apply regex filters in Nushell (SQLite doesn't support all regex features)
    let filtered_results = if $regex_filters == [] {
        $results
    } else {
        $regex_filters | reduce -f $results {|pattern, acc|
            $acc | where command =~ $pattern
        }
    }

    # Format timestamps as human readable
    let formatted_results = $filtered_results | update start_timestamp {|row|
        # Convert nanoseconds to seconds and format
        $row.start_timestamp // 1000000000 | into datetime
    }

    # Add pipe count column
    let final_results = $formatted_results | insert pipes {|i|
        ast --flatten $i.command | where shape == shape_pipe | length
    }

    # Display in visidata or return
    if $not_in_vd {
        $final_results
    } else {
        $final_results | in-vd history
    }
}

export def 'in-vd history' [] {
    where command !~ 'in-vd history'
    | to csv
    | vd --save-filetype csv --filetype csv -o -
    | complete
    | get stdout
    | if ($in == null) { return } else { }
    | from csv
    | get command
    | reverse
    | str join $'(char nl)'
    | str replace -r ';.+?\| in-vd;' ';'
    | commandline edit -r $in
}
