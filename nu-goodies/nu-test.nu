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

const nightly_path = '~/temp/nu-nightly' | path expand

export def --env download-nushell-nightly [
  --arch (-a): string = 'aarch64-apple-darwin'    # archicture as specified in nushell/nightly repo
  --ext (-e): string = '.tar.gz'                      # extension, including the leading dot (e.g. '.tar.gz')
  --destination_dir (-d): directory = $nightly_path   # destination directory in which to save the download
] {
  let most_recent_nightly = (http get https://api.github.com/repos/nushell/nightly/releases | get 0)
  let nightly_name = ($most_recent_nightly.name | str replace -r '^Nu-nightly-' '')
  let asset = http get $most_recent_nightly.assets_url
  | where name =~ $arch
  | where name =~ $'($ext)$'
  | get 0

  let filename = (
    $asset.name
    | str replace -r $ext $'-($nightly_name)($ext)'
    | str replace -r '^nu-' 'nu-nightly-'
  )

  let destination_file = ($destination_dir | path join $filename)

  print $"Downloading to:(char lf)($destination_file)"

  http get $asset.browser_download_url | save $destination_file
  tar -C $nightly_path -xzf $destination_file
}

export def launch-downloaded [] {
  let path = glob ($nightly_path | path join *darwin *nu) | sort | last
  commandline edit -r $path
}
