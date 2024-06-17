export def nu-test-install [
    --nushell
    --polars
    --no-launch
    --plugin-config: path = '/Users/user/.test_config/nushell/polars_test.msgpackz'
    --pr: string
] {
    cd /Users/user/git/nushell/

    git checkout main
    git pull

    if $pr != null {
        gh co $pr
    }

    $env.CARGO_HOME = ("~/.cargo_test" | path expand)

    if $polars or not $nushell {
        cargo install --path /Users/user/git/nushell/crates/nu_plugin_polars
        cp /Users/user/.cargo_test/bin/nu_plugin_polars $'/Users/user/.cargo_test/bin/backups/nu_plugin_polars(date now | format date %F)'

        plugin add '/Users/user/.cargo_test/bin/nu_plugin_polars' --plugin-config $plugin_config
        print 'test plugin updated' ''
    }

    if $nushell or not $polars {
        cargo install --path .
        cp /Users/user/.cargo_test/bin/nu $'/Users/user/.cargo_test/bin/backups/nu(date now | format date %F)'
        print 'test nushell updated' ''
    }

    if not $no_launch {
        commandline edit -r $'^/Users/user/.cargo_test/bin/nu --plugin-config ($plugin_config)'
    }
}
