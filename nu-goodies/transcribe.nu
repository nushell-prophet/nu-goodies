export def main [file: path] {
    let $file = $file
        | if $in =~ '\.wav$' {} else {
            let $f = $in + '.wav';
            ffmpeg -i $file -ar 16000 $f;
            $f
        }

    (^/Users/user/git/whisper.cpp/main -f $file
        -m /Users/user/git/whisper.cpp/models/ggml-base.en.bin
        -otxt $'($file).txt' -osrt $'($file).srt' -np )
}
