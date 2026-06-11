#!/usr/bin/env nu

# update-public-git.nu - Update public repository with patches from private repo

export def main [
    private_repo: string # Path to private repository
    public_repo: string # Path to public repository
    --from-tag (-f): string # Create patches from this tag
    --from-commit (-c): string # Create patches from this commit
    --last (-l): int # Create patches for last N commits
    --dry-run (-d) # Show what would be done without applying
    --clean # Clean patch directory after applying
] {

    # Validate inputs
    if not ($private_repo | path exists) {
        error make {msg: $"Private repo path does not exist: ($private_repo)"}
    }

    if not ($public_repo | path exists) {
        error make {msg: $"Public repo path does not exist: ($public_repo)"}
    }

    let patch_dir = "temp-patches"

    # Determine patch source
    let patch_source = if ($from_tag != null) {
        $from_tag
    } else if ($from_commit != null) {
        $from_commit
    } else if ($last != null) {
        $"HEAD~($last)"
    } else {
        error make {msg: "Must specify --from-tag, --from-commit, or --last"}
    }

    print $"🔄 Updating public repo from private repo"
    print $"   Private: ($private_repo)"
    print $"   Public:  ($public_repo)"
    print $"   Source:  ($patch_source)"

    # Change to private repo and create patches
    cd $private_repo

    # Check if we're in a git repo
    if not (".git" | path exists) {
        error make {msg: $"Not a git repository: ($private_repo)"}
    }

    # Show what commits will be included
    let commits = git log --oneline $"($patch_source)..HEAD" | lines

    if ($commits | is-empty) {
        print "✅ No new commits to patch"
        return
    }

    print $"\n📝 Commits to be patched:"
    $commits | each {|commit| print $"   ($commit)" }

    if $dry_run {
        print "\n🏃 Dry run - would create patches but not apply them"
        return
    }

    # Create patches directory
    mkdir $patch_dir

    # Generate patches
    print $"\n📦 Creating patches..."
    git format-patch $patch_source -o $patch_dir

    let patches = $patch_dir | path join '*.patch' | ls $in | get name | sort

    if ($patches | is-empty) {
        print "❌ No patches created"
        return
    }

    print $"✅ Created ($patches | length) patches"

    # Change to public repo and apply patches
    cd $public_repo

    # Check if we're in a git repo
    if not (".git" | path exists) {
        error make {msg: $"Not a git repository: ($public_repo)"}
    }

    # Check if repo is clean
    let status = (git status --porcelain | lines)
    if not ($status | is-empty) {
        error make {msg: "Public repo has uncommitted changes. Please commit or stash them first."}
    }

    print $"\n🔧 Applying patches to public repo..."

    # Apply each patch
    mut success_count = 0
    mut failed_patches = []

    for patch in $patches {
        let patch_name = ($patch | path basename)
        print $"   Applying ($patch_name)..."

        let result = (do { git am $patch } | complete)

        if $result.exit_code == 0 {
            $success_count = $success_count + 1
            print $"   ✅ ($patch_name)"
        } else {
            $failed_patches = ($failed_patches | append $patch_name)
            print $"   ❌ ($patch_name): ($result.stderr)"

            # Abort the failed patch
            git am --abort
            break
        }
    }

    # Summary
    print $"\n📊 Summary:"
    print $"   Successfully applied: ($success_count)/($patches | length) patches"

    if not ($failed_patches | is-empty) {
        print $"   Failed patches: ($failed_patches | str join ', ')"
        print "\n💡 To resolve conflicts manually:"
        print "   1. git am --abort (if needed)"
        print $"   2. git am ($failed_patches | first)"
        print "   3. Resolve conflicts and run: git am --continue"
    } else {
        print "   🎉 All patches applied successfully!"
    }

    # Clean up patches if requested
    if $clean and ($failed_patches | is-empty) {
        cd $private_repo
        rm --recursive --force $patch_dir
        print $"\n🧹 Cleaned up patch directory"
    } else {
        cd $private_repo
        print $"\n📁 Patches saved in: ($patch_dir)/"
    }
}
