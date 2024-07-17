# https://discord.com/channels/601130461678272522/615253963645911060/1182672999921504336
# by @melmass at discord

# interactively select columns from a table
export def main [] {
    let tgt = $in
    let $choices = $tgt
        | columns
        | input list -m "Pick columns to get: "
        | str join " "

    history
    | last
    | get command
    | str replace 'select-i' $'select ($choices)'
    | commandline edit -r $in
}
