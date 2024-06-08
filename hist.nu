alias core_hist = history
use in-vd.nu history

# add useful columns for history filtering, uses the first argument as a regex to filter commands
export def main [
    ...query: string
    --entries: int = 5000 # the number of last entries to work with
    --all                   # return all the history
    --session (-s)  # show only entries from session
    --folder
    --last_x: duration # duration for the period to check commands
    --in_vd (-v) # open in vd
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
    | if ('duration_s' in ...($in | columns)) {} else {
        upsert duration_s {|i| $i.duration | into int | $in / (10 ** 9)}
        | reject -i item_id duration hostname
        | move start_timestamp --after command
        | upsert pipes {|i| $i.command | split row -r '\s\|\s' | length}
    }
    | if $in_vd {
        history
    } else {}
}
