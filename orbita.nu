export def main [] {
    1..14 | each {line ' '}
}

def line [
    symbol: string
] {
    1..61 | each {$symbol} | str join
}
