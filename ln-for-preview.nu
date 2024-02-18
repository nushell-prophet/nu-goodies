export def --env main [
    --first: int = 500
]: [list -> nothing, table -> nothing] {
    let $input = $in
    let $temp_path = $nu.temp-path | path join 'hard_links' (date now | format date "%Y%m%d_%H%M%S")

    mkdir $temp_path

    $input
    | first $first
    | if ($in | describe | $in =~ '^table') {
        if ($in | columns | 'name' in $in) {
            where type == file
            | get name
            | each {|i| ln $i $temp_path}
        } else {
            error make {msg: 'no name column in input table'}
        }
    } else if ($in | describe | $in =~ '^list') {
        each {|i| ln $i $temp_path}
    }

    cd $temp_path
}
