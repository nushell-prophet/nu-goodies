# Nushell Key-Value Store (kv)
# Original version by @clipplerblood
# https://discord.com/channels/601130461678272522/615253963645911060/1149709351821516900

# Aliases to avoid conflicts with custom 'get' and 'ls' functions
alias core_get = get
alias core_ls = ls

# Display the KV store as a table with latest version of each key
export def ls [] {
    let values_path = kv-path
    let files = core_ls -s $values_path

    if ($files | is-empty) { return [] }

    # Parse filenames, group by key, and show latest version with modification time (newest first)
    $files
    | each {|file|
        {
            key: (parse-filename $file.name).key
            modified: ($file.modified | date humanize)
            file_modified: $file.modified
        }
    }
    | group-by key
    | items {|key files|
        let latest = $files | sort-by file_modified --reverse | first
        {name: $key modified: $latest.modified file_modified: $latest.file_modified}
    }
    | sort-by file_modified --reverse
    | select name modified
}

# Return the path to the KV store values folder
def kv-path []: nothing -> path {
    $env.kv?.path?
    | default { $nu.data-dir | path join 'kv' }
    | path join 'values'
    | if ($in | path exists) { } else {
        tee { mkdir $in }
    }
}

# Initialize the KV store with optional custom directory
export def --env init [
    dir?: path # Custom directory path for KV store
    --reset # Delete existing values folder before initialization
] {
    if $dir != null { $env.kv.path = $dir }

    let values_folder = kv-path

    if $reset and ($values_folder | path exists) {
        rm -rf $values_folder
    }

    mkdir $values_folder
}

# Load the KV store by scanning the filesystem and building a record of latest files per key
def load-kv []: nothing -> record {
    let values_path = kv-path
    let files = core_ls -s $values_path

    if ($files | is-empty) {
        return {}
    }

    # Parse filenames and group by key, keeping only the latest file for each key
    $files
    | each {|file|
        {
            key: (parse-filename $file.name).key
            filename: $file.name
            modified: $file.modified
        }
    }
    | group-by key
    | items {|key files|
        {key: $key filename: ($files | sort-by modified --reverse | first).filename}
    }
    | transpose -r -d
}

# Generate a timestamped filename
def date-now [] {
    date now | format date "%Y%m%d_%H%M%S_%f"
}

# Get the full path to a value file in the values folder
def value-path [filename: string]: nothing -> path {
    kv-path | path join $filename
}

# Parse a filename to extract the key name and timestamp
# Filename format: {key}_{timestamp}.{extension}
# Example: mykey_20231116_215130_123456.txt -> {key: "mykey", timestamp: "20231116_215130_123456", extension: "txt"}
def parse-filename [filename: string]: nothing -> record {
    let parts = $filename | path parse
    let stem = $parts.stem

    # Find the last occurrence of underscore followed by a timestamp pattern
    # Timestamp format: YYYYMMDD_HHMMSS_ffffff
    let match = $stem | parse -r '(?P<key>.+?)_(?P<timestamp>\d{8}_\d{6}_\d+)$'

    if ($match | is-empty) {
        # If parsing fails, treat entire stem as key
        {key: $stem timestamp: "" extension: $parts.extension}
    } else {
        let parsed = $match | first
        {key: $parsed.key timestamp: $parsed.timestamp extension: $parts.extension}
    }
}

# Get all files for a specific key, sorted by timestamp (newest first)
def files-for-key [key: string]: nothing -> table {
    core_ls -s (kv-path)
    | where {|file|
        let parsed = parse-filename $file.name
        $parsed.key == $key
    }
    | sort-by modified --reverse
}

# Resolve value from either parameter or pipeline input
def resolve-value [param_value?: any]: any -> any {
    let input = $in
    if $param_value != null { $param_value } else { $input }
}

# Set a value in the KV store, optionally taking input from the pipeline
export def --env set [
    key: string = 'last' # Specify the key to set
    value?: any # Provide the value to set (optional if used in a pipeline)
    --return-to-stdout (-p) # Output the input value back to the pipeline
    --extension (-e): string = '' # Specify the file extension for saving
    --cwd # Set KV directory in current folder
]: any -> any {
    let input = $in # Store input for potential return at end of command
    let value_to_store = $in | resolve-value $value

    if $cwd {
        $env.kv.path = (pwd | path join nushell-kv)
        if $value_to_store == null { return }
    }

    # Determine the file extension based on the value type
    let file_extension = if $extension != '' {
        $extension
    } else {
        let value_type = $value_to_store | describe

        if $value_type == 'string' {
            'txt' # 'msgpackz' cannot reliably store primitives
        } else {
            'nuon' # Use Nuon for non-string values (supports version control)
        }
    }

    # Generate a unique filename for the value
    let filename = $"($key)_(date-now).($file_extension)"
    let file_path = value-path $filename

    # Save the value to the file
    $value_to_store
    | if $file_extension == 'nuon' { to nuon --indent 4 } else { $in }
    | save --raw=($file_extension == 'nuon') $file_path

    # Filesystem scanning will discover this file automatically

    if $env.kv?.print-tables? == true {
        print $'You can preview this variable with `kv get ($key)`' ($value_to_store | table -e)
    }

    # Output the input value if -p is specified
    if $return_to_stdout { return $input }
}

# Get a value from the KV store
export def get [
    key: string@'nu-complete-key-names' = 'last' # Specify the key to retrieve
    --optional (-o) # Return null instead of error if key doesn't exist
] {
    load-kv
    | if $key in $in {
        let filename = core_get $key
        value-path $filename | open
    } else {
        if $optional { return } else {
            error make --unspanned {msg: $'there is no `($key)` key in the KV store'}
        }
    }
}

# Retrieve a file by its filename from the values folder
export def get-file [
    filename: string@'nu-complete-file-names' = '' # Specify the filename to retrieve
] {
    if $filename == '' {
        core_ls (kv-path)
        | sort-by modified -r
    } else {
        value-path $filename | open
    }
}

# Delete a key from the KV store (removes all versions)
export def del [
    key: string@'nu-complete-key-names' = 'last' # Specify the key to delete
] {
    # Find and delete all files matching this key
    let files = files-for-key $key

    if ($files | is-empty) {
        error make --unspanned {msg: $'there is no `($key)` key in the KV store'}
    }

    $files.name | each {|name| rm (value-path $name) }
}

# Reset the KV store (delete all files in the 'values' folder)
export def reset [] {
    # Confirm before resetting
    [false true]
    | input list 'confirm'
    | if $in {
        let values_folder = kv-path
        rm -rf $values_folder
        mkdir $values_folder
    }
}

# Push a value to a list in the KV store
export def push [
    key: string # Specify the key to push to
    value?: any # Provide the value to push (optional if used in a pipeline)
    -p # Output the input value back to the pipeline
    -u # Ensure uniqueness by removing duplicates before appending
]: any -> any {
    let value_to_push = $in | resolve-value $value

    if $value_to_push == null {
        error make {msg: "No value provided to push"}
    }

    # Get existing value or start with empty list
    let stored_list = get $key --optional | default []

    if not ($stored_list | is-empty) and not ($stored_list | describe | str starts-with 'list') {
        error make {msg: $"Key '($key)' is not associated with a list"}
    }

    let updated_list = if $u {
        # Ensure uniqueness
        $stored_list | where {|x| $x != $value_to_push } | append $value_to_push
    } else {
        # Simply append the new value
        $stored_list | append $value_to_push
    }

    # Save the updated list using the set command
    set $key $updated_list

    # Output the input value if -p is specified
    if $p { return $value_to_push }
}

# Get and remove the last value from a list in the KV store
# Example:
# > kv set my-stack ["hello", "world"]
# > kv pop my-stack
# world
#
# > kv pop my-stack
# hello
#
# > kv get my-stack
# ╭────────────╮
# │ empty list │
# ╰────────────╯
export def "pop" [
    key: string@'nu-complete-key-names' = 'last' # Specify the key to pop from
] {
    let stored = get $key

    if ($stored | is-empty) { return }

    let value = $stored | last
    set $key ($stored | drop)

    $value
}

# Helper to create completion records
def make-completion []: table -> record {
    {
        completions: ($in | rename value description)
        options: {sort: false}
    }
}

# Autocompletion for key names
def nu-complete-key-names [] {
    ls | make-completion
}

# Autocompletion for file names in the values folder
def nu-complete-file-names [] {
    core_ls -s (kv-path)
    | sort-by modified --reverse
    | select name modified
    | update modified { date humanize }
    | make-completion
}

# Conditionally store a value if debug-catch mode is enabled
export def kv-catch [
    key: string # Specify the key to store the value under
    value?: any # Provide the value to store (optional if used in a pipeline)
    -p # Pass value to output
] {
    let value = $in | resolve-value $value

    if $env.kv?.debug-catch? == true {
        let modified_key = $env.kv?.debug-tag?
            | if $in != null { $'($key)_($in)' } else { $key }

        kv set $modified_key $value
    }

    if $p { $value }
}
