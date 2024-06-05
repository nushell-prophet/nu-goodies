# author @CabalCrow
# https://discord.com/channels/601130461678272522/615253963645911060/1247651613531705436

# <() from bash.
#
# The closure parameter is used, or the string stdin. Can take both applying
# the stdin first. If no stdin is used closure takes no argument & the output is
# used as the file content. If there is stdin closure takes the file name as an
# argument & operates on it.
export def command-to-temp-file [
    expression?: closure     # Commands used to generate the content of the file.
]: [string -> path, nothing -> path] {
    let content = $in | default ""
    let output_file = mktemp -t
    if $content != "" {
        $content | save -f $output_file
        if $expression != null {
            do $expression $output_file
        }
        return $output_file
    }
    do $expression | default "" o> $output_file
    $output_file
}
