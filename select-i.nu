# https://discord.com/channels/601130461678272522/615253963645911060/1182672999921504336
# by @melmass at discord

# interactively select columns from a table
export def iselect [] {
    let tgt = $in
    let cols = ($tgt | columns)

    let choices = ($cols | input list -m "Pick columns to get: ")
    $tgt | select $choices

}
