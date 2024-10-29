# install nushell or polars from the HEAD or the specified PR
export def install [
    --nushell # update nushell only
    --polars # update polars plugin only
    --nushell-repo-path: path = '/Users/user/git/nushell/'
    --cargo-test-path: path = '/Users/user/.cargo_test/'
    --plugin-config: path = '/Users/user/.test_config/nushell/polars_test.msgpackz'
    --pr: string # a pr to checkout like ayax79:polars_pivot
] {
    cd $nushell_repo_path

    git checkout main
    git pull

    if $pr != null {
        gh co $pr
    }

    mkdir $cargo_test_path
    $env.CARGO_HOME = $cargo_test_path

    # I install polars first to add it later to already updated nushell
    if $polars or not $nushell {
        cargo install --path ([$nushell_repo_path crates nu_plugin_polars] | path join)

        plugin add ([$cargo_test_path bin nu_plugin_polars] | path join) --plugin-config $plugin_config
        print 'test plugin updated' ''
    }

    if $nushell or not $polars {
        cargo install --path $nushell_repo_path
        print 'test nushell updated' ''
    }

    commandline edit -r $'^($cargo_test_path | path join bin nu) --plugin-config ($plugin_config)'
}

export def launch [
    --no-plugin
] {
    let $exec = '/Users/user/.cargo_test/' | path join bin nu
    let $params = [
            "--execute" "$env.PATH = ($env.PATH | prepend '/Users/user/.cargo_test/bin/')"
        ]
        | if $no_plugin {} else {
           prepend ['--plugin-config' '/Users/user/.test_config/nushell/polars_test.msgpackz']
        }

    ^$exec ...$params
}
