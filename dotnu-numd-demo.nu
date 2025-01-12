# first we use dotnu to extract commands
dotnu parse-docstrings nu-goodies/commands.nu
| get command_name
# for some reason the commands below produce errors in my case
| where $it not-in ['ln-for-preview', 'significant-digits', 'to-safe-filename']
| each {|command|
    ''
    | append $"# ($command)\n" # markdown header
    | append "```nu"
    | append $"> ($command) --help | numd parse-help" # command inside of ```nu block
    | append "```\n"
}
| prepend $"```nu\n use nu-goodies/commands.nu *\n```\n" # my import command
| to text
| save commands-help.md -f;

# here we execute numd to populate ```nu blocks with commands execution
numd run commands-help.md --intermed-script commands-help-demo.nu ;
