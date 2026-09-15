# Jump to a project under ~/repos in the current shell.
# Usage: repo [name]   (fzf picker when name is omitted)
# Picker keys: Enter cd here, global Alt-C/F/T/N, Alt-I insert path.
repo() {
  emulate -L zsh
  setopt localoptions null_glob
  local name dir d base
  local -a all matches
  case ${1-} in
    -h|--help) print 'Usage: repo [name]'; return 0 ;;
  esac
  (( $# <= 1 )) || { print 'Usage: repo [name]' >&2; return 2; }
  for d in ~/repos/*/ ~/repos/*/*/; do
    [[ -d ${d}.git ]] && all+=(${d%/})
  done
  if (( $# == 0 )); then
    (( ${#all} )) || { print 'No git repos under ~/repos.' >&2; return 1; }
    local out key sel
    out=$(printf '%s\n' "${all[@]}" | fzf --prompt='repo> ' \
      --preview '$HOME/.local/bin/fz-preview {}' \
      --expect=alt-i) || return $?
    key=$(print -r -- "$out" | sed -n 1p)
    sel=$(print -r -- "$out" | sed -n 2p)
    [[ -n $sel ]] || return 0
    if [[ $key == alt-i ]]; then print -z "${sel} "; return 0; fi
    dir=$sel
  elif (( $# == 1 )); then
    name=$1
    for d in "${all[@]}"; do
      base=${d##*/}
      [[ $base == "$name" ]] && matches+=($d)
    done
    if (( ${#matches} == 1 )); then
      dir=$matches[1]
    elif (( ${#matches} > 1 )); then
      dir=$(printf '%s\n' "${matches[@]}" | fzf --prompt='repo> ') || return $?
      [[ -n $dir ]] || return 0
    else
      print "Unknown repo: $name" >&2
      printf '  %s\n' "${all[@]##*/}" >&2
      return 1
    fi
  else
    print 'Usage: repo [name]' >&2
    return 2
  fi
  cd -- "$dir"
}
