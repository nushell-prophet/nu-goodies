# fill missing columns for each row
#
# this is how empty columns are present
# > [{a: 1} {b: 2}] | to nuon
# [{a: 1}, {b: 2}]
#
# > [{a: 1} {b: 2}] | fill non-exist | to nuon
# [[a, b]; [1, null], [null, 2]]
export def main [
    value_to_replace: any = ''
] {
    let $table = $in

    $table
    | columns
    | reduce --fold $table {|i acc|
        $acc
        | default $value_to_replace $i
    }
}
