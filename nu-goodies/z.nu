export def --env main [...rest --interactive(-i)] {
  let $query = $rest  | str join ' '

  open $nu.history-path
  | query db "select distinct(cwd) from history order by id desc"
  | get cwd
  | to text
  | if $interactive {
      fzf --scheme=path -q $query
  } else {
      fzf --scheme=path -f $query | lines | first
  }
  | path expand
  | cd $in
}
