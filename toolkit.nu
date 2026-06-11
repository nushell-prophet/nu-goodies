const upstream = 'https://api.github.com/repos/nushell-prophet/nu-kv/tarball'
const local_src = '../nu-kv/kv'
const dest = 'nu-goodies/kv'

export def main [] { }

# Refresh nu-goodies/kv/ from upstream nu-kv.
export def 'main update-kv' [--local (-l)] {
    rm --recursive --force $dest
    mkdir $dest

    if $local {
        ^rsync -a --exclude='.git' $"($local_src)/" $"($dest)/"
    } else {
        let tmp = mktemp --directory
        ^curl -sL $upstream | ^tar xz -C $tmp --strip-components=1
        ^rsync -a --exclude='.git' $"($tmp)/kv/" $"($dest)/"
        rm --recursive --force $tmp
    }
}
