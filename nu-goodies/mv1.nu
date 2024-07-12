export def main [
    file: path
] {
    if ($file | str ends-with '_back') {
        mv $file $"($file | str replace -r '_back$' '')"
    } else {
        mv $file $'($file)_back'
    }
}
