# hardlink an input table to temp directory (useful for previewing files from large directories in external programs)
#
# > ls | where modified > (date now | $in - 20min) | ln-for-preview
export def --env main [
    --first: int = 500
]: [list -> nothing, table -> nothing] {
    let $input = $in
    let $temp_path = [
            $nu.temp-path
            'hard_links'
            (date now | format date "%Y%m%d_%H%M%S")
        ]
        | path join

    mkdir $temp_path

    $input
    | first $first
    | if ($in | describe | $in =~ '^table') {
        if ($in | columns | 'name' in $in) {
            where type == file
            | get name
            | each {ln $in $temp_path}
        } else {
            error make {msg: 'no name column in input table'}
        }
    } else if ($in | describe | $in =~ '^list') {
        each {ln $in $temp_path}
    }

    cd $temp_path
}
