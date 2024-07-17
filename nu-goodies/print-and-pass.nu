# An alternative to `inspect` that doesn't break debugging output
export def main [
    callback?: closure
] {
    let $input = $in

    if $callback == null {
        print $input
    } else {
        print (do $callback $input)
    }

    $input
}
