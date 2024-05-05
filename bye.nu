use gradient-screen.nu

export def main [
    ...strings: string
    --no_date # don't append date
    -n # don't quit
] {
    gradient-screen ...$strings --no_date=$no_date
    if not $n {exit}
}
