# https://discord.com/channels/601130461678272522/615253963645911060/1182672999921504336
# by @melmass at discord

# interactively select columns from a table
export def main [] {
    let tgt = ($in)
    let cols = ($tgt | columns)

    let $choices = ($cols | input list -m "Pick columns to get: ")
    
    history 
    | last 
    | get command 
    | str replace 'select-i' $'select ($choices | str join " ")'
    | commandline $in
}
