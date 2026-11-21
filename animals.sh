#!/bin/bash
# 動いているすべてのエージェントに動物の絵文字を割り当て、
# Agents 一覧のエージェント名を「🐶 kiro」の形にする。
#
#   animals.sh        割り当てを見直す（イベントのたびに呼ばれる）
#   animals.sh fill   見直したうえで、動物が足りず印（🐾）が付いたエージェントにも、空いた動物を付ける
#   animals.sh pick   動物を選ぶ画面を開く
set -u
. "$(dirname "$0")/lib.sh"
jq=$(command -v jq || echo /opt/homebrew/bin/jq)
mode="${1:-}"

if [ "$mode" = pick ]; then
  # アクションは画面を持たないので、選ぶ画面（picker.sh）を herdr に開いてもらう。
  exec "$herdr" plugin pane open --plugin "$plugin_id" --entrypoint picker --focus >/dev/null
fi

state="$state_dir/assigned.tsv" # 端末ID <TAB> ペインID <TAB> 動物（足りなかったときは -）
lock="$state_dir/lock"
mkdir -p "$state_dir"
ensure_conf

# イベントが続けて来ても、割り当てが競合しないよう 1 つずつ動かす。
tries=0
until mkdir "$lock" 2>/dev/null; do
  tries=$((tries + 1))
  if [ "$tries" -ge 50 ]; then # 5 秒待っても空かなければ、残った古いロックとみなす
    rmdir "$lock" 2>/dev/null
    tries=0
  fi
  sleep 0.1
done
trap 'rmdir "$lock" 2>/dev/null' EXIT

# 一覧を取れなかったときは何も変えない（全員の動物を消してしまわないため）。
listed=$("$herdr" agent list) || exit 1
live=$(printf '%s' "$listed" | "$jq" -er '.result.agents | if type == "array" then .[] else error("agents がない") end | [.terminal_id, .pane_id, .agent, (.display_agent // "")] | @tsv' 2>/dev/null)
# jq -e は、一覧が空のとき 4 を返す。それ以外の失敗（JSON でない、agents がない）は中止する。
case $? in 0 | 4) ;; *) exit 1 ;; esac

animals=$(read_animals)
overflow=$(read_overflow)
count=$(printf '%s\n' "$animals" | awk 'NF' | wc -l | tr -d ' ')

touch "$state"
old=$(cat "$state")
new=""
used=""

report() { "$herdr" pane report-metadata "$1" --source "$plugin_id" "${@:2}" </dev/null >/dev/null 2>&1; }

# そのエージェントに付けたままにする動物を返す。なければ空。
kept() {
  local animal
  animal=$(printf '%s\n' "$old" | awk -F'\t' -v t="$1" '$1 == t { print $3; exit }')
  if [ "$animal" = - ]; then
    [ "$mode" = fill ] || echo -
  elif [ -n "$animal" ] && printf '%s\n' "$animals" | grep -qxF "$animal"; then
    echo "$animal"
  fi
}

# 1. いなくなったエージェントのペインから、絵文字付きの名前を消す。
while IFS=$'\t' read -r term pane animal; do
  [ -n "$term" ] || continue
  printf '%s\n' "$live" | cut -f1 | grep -qxF "$term" || report "$pane" --clear-display-agent
done <<<"$old"

# 2. すでに決まっている動物を「使用中」にする。
while IFS=$'\t' read -r term pane agent shown; do
  [ -n "$term" ] || continue
  animal=$(kept "$term")
  [ -z "$animal" ] || [ "$animal" = - ] || used="$used$animal"$'\n'
done <<<"$live"

# 3. 動いているエージェントに動物を決めて、名前を送る。
while IFS=$'\t' read -r term pane agent shown; do
  [ -n "$term" ] || continue
  if [ "$count" -eq 0 ]; then # 動物を 1 つも選んでいなければ、元の名前に戻す
    [ -z "$shown" ] || report "$pane" --clear-display-agent
    continue
  fi
  animal=$(kept "$term")
  if [ -z "$animal" ]; then
    # 使われていない動物のうち、いちばん先のもの。なければ、足りないときの印。
    animal=$(printf '%s\n' "$animals" | grep -vxF -f <(printf '%s' "$used") | head -n 1)
    if [ -n "$animal" ]; then used="$used$animal"$'\n'; else animal=-; fi
  fi
  new="$new$term"$'\t'"$pane"$'\t'"$animal"$'\n'
  if [ "$animal" = - ]; then want="$overflow $agent"; else want="$animal $agent"; fi
  [ "$shown" = "$want" ] || report "$pane" --display-agent "$want"
done <<<"$live"

printf '%s' "$new" >"$state.tmp" && mv "$state.tmp" "$state"
