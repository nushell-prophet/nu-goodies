# author @CabalCrow
# https://discord.com/channels/601130461678272522/615253963645911060/1247651613531705436

# <() from bash.
#
# The closure parameter is used, or the string stdin. Can take both applying
# the stdin first. If no stdin is used closure takes no argument & the output is
# used as the file content. If there is stdin closure takes the file name as an
# argument & operates on it.
export def main [
    content?     # Commands used to generate the content of the file.
] {
    let content = if $content == null {} else {$content}
    let output_file = $nu.temp-path
        | path join $'(date now | into int).yaml'

    $content | save $output_file

    $output_file
}
