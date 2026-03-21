export use commands.nu [
    ls
    set
    get
    get-file
    del
    reset
    push
    pop
    init
]

# kv module respects $env.kv.path for locating it's cache
export def main [] { ls }
