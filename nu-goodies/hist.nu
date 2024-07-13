alias core_hist = history
use in-vd.nu

# Filter history with regex and convenient flags, add useful columns
export def main [
    ...query: string # a regex to search for
    --entries: int = 5000 # a number of last entries to work with
    --all (-a) # return all the history
    --session (-s) # show only entries from the current session
    --folder # show only entries from the current folder
    --last_x: duration # duration for the period to check commands
    --not_in_vd (-V) # disable opening command in visidata
] {
    if $in != null {} else {
        core_hist -l
        | if $session {
            where session_id == (history session)
        } else if $folder {
            where cwd == (pwd)
        } else if ($entries == 0) or $all {} else {
            last $entries
        }
    }
    | if $last_x != null {
        where start_timestamp > ((date now) - $last_x | format date '%F %X')
    } else {}
    | if $query == [] {} else {
        let $inp = $in

        $query
        | reduce -f $inp {|it acc|
            $acc | filter {|i| $i.command =~ $it}
        }
    }
    | if 'duration_s' in ...($in | columns) {} else {
        insert duration_s {|i| $i.duration | into int | $in / (10 ** 9)}
        | reject -i item_id duration hostname
        | move start_timestamp --after command
        | upsert pipes {|i| $i.command | split row -r '\s\|\s' | length}
    }
    | if $not_in_vd {} else {
        in-vd history
    }
}
