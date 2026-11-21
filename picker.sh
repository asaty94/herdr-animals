#!/bin/bash
# 動物を選ぶ画面。herdr のポップアップの中で動く。
#   ↑↓ / k j  移動        space  チェックを付ける・外す（付けた動物は末尾に入る）
#   t         先頭へ      K J    1 つ上へ・下へ
#   enter     保存        q / esc  やめる
. "$(dirname "$0")/lib.sh"
ensure_conf

overflow=$(read_overflow)
sel=()  # チェックした動物（優先順）
all=()  # 一覧に出すすべての動物（catalog.txt と、設定にだけある動物）
while IFS= read -r a; do [ -n "$a" ] && sel+=("$a"); done < <(read_animals)
while IFS= read -r a; do [ -n "$a" ] && all+=("$a"); done < <({ catalog; read_animals; } | awk '!seen[$0]++')
items=() # 画面に出す順。チェックした動物、続けてそれ以外
cursor=0

selected_index() { # チェックした動物の中での位置。なければ -1
  local i
  for i in "${!sel[@]}"; do [ "${sel[$i]}" = "$1" ] && { echo "$i"; return; }; done
  echo -1
}

rebuild() {
  local a
  items=("${sel[@]}")
  for a in "${all[@]}"; do [ "$(selected_index "$a")" -ge 0 ] || items+=("$a"); done
}

remove_selected() { # sel から $1 番目を外す
  local i kept=()
  for i in "${!sel[@]}"; do [ "$i" -eq "$1" ] || kept+=("${sel[$i]}"); done
  sel=("${kept[@]}")
}

toggle() {
  local item=${items[$cursor]} at
  at=$(selected_index "$item")
  if [ "$at" -ge 0 ]; then remove_selected "$at"; else sel+=("$item"); fi
  rebuild
}

to_top() {
  local item=${items[$cursor]} at
  at=$(selected_index "$item")
  [ "$at" -lt 0 ] || remove_selected "$at"
  sel=("$item" "${sel[@]}")
  rebuild
  cursor=0
}

shift_by() { # チェックした動物を 1 つ上（-1）か下（1）へ
  local to=$((cursor + $1)) item
  [ "$cursor" -lt "${#sel[@]}" ] && [ "$to" -ge 0 ] && [ "$to" -lt "${#sel[@]}" ] || return
  item=${sel[$cursor]}
  sel[$cursor]=${sel[$to]}
  sel[$to]=$item
  cursor=$to
  rebuild
}

move() {
  cursor=$((cursor + $1))
  [ "$cursor" -ge 0 ] || cursor=0
  [ "$cursor" -lt "${#items[@]}" ] || cursor=$((${#items[@]} - 1))
}

top=0 # 画面のいちばん上に出す行
render() {
  local rows i mark line
  rows=$(stty size 2>/dev/null | cut -d' ' -f1)
  rows=$((${rows:-24} - 5))
  [ "$rows" -ge 3 ] || rows=3
  [ "$cursor" -ge "$top" ] || top=$cursor
  [ "$cursor" -lt $((top + rows)) ] || top=$((cursor - rows + 1))
  printf '\033[H\033[J 動物を選ぶ（上から順に使う。足りないときは %s）\n\n' "$overflow"
  for ((i = top; i < top + rows && i < ${#items[@]}; i++)); do
    if [ "$i" -lt "${#sel[@]}" ]; then mark=$(printf '[x] %2d' $((i + 1))); else mark='[ ]   '; fi
    line=" $mark  ${items[$i]}"
    if [ "$i" -eq "$cursor" ]; then printf '\033[7m%s \033[0m\n' "$line"; else printf '%s\n' "$line"; fi
  done
  printf '\n space: チェック  t: 先頭へ  K/J: 上へ/下へ  enter: 保存  q: やめる'
}

rebuild
[ -t 1 ] && printf '\033[?25l' && trap 'printf "\033[?25h\033[H\033[J"' EXIT
while :; do
  [ -t 1 ] && render
  IFS= read -rsn1 key || exit 0 # 入力が切れたら保存せずに終える
  case "$key" in
    '') break ;; # enter
    q) exit 0 ;;
    $'\e')
      IFS= read -rsn2 -t 1 rest || exit 0 # esc だけならやめる
      case "$rest" in '[A') move -1 ;; '[B') move 1 ;; esac
      ;;
    k) move -1 ;;
    j) move 1 ;;
    ' ') toggle ;;
    t) to_top ;;
    K) shift_by -1 ;;
    J) shift_by 1 ;;
  esac
done

write_conf "$overflow" "${sel[@]}"
bash "$root/animals.sh" fill
