# open table in Less
export def main [
    --abbreviated(-a): int = 1000
    --bat(-b) # use bat instead of less
] {
    table -e --abbreviated $abbreviated | into string | if $bat {bat} else {less -R}
}
