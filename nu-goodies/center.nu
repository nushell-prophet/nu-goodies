export def main [
    --factor: int = 1
] {
    fill -a center --width ((term size).columns // $factor)
}
