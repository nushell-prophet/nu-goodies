# open table in Less
export def main [
    --abbreviated(-a): int = 1000
    --bat(-b)
] {
    table -e --abbreviated $abbreviated | into string | if $bat {bat} else {less -R}
}
