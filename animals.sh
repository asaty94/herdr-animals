#!/bin/bash
# 動いているすべてのエージェントに動物の絵文字を割り当て、
# Agents 一覧のエージェント名を「🐶 kiro」の形にする。
# 仕様: specification/plugin.md
set -u

herdr="${HERDR_BIN_PATH:-herdr}"
jq=$(command -v jq || echo /opt/homebrew/bin/jq)
source_id="${HERDR_PLUGIN_ID:-asaty94.animals}"
root="${HERDR_PLUGIN_ROOT:-$(cd "$(dirname "$0")" && pwd)}"
config_dir="${HERDR_PLUGIN_CONFIG_DIR:-$root/.config}"
state_dir="${HERDR_PLUGIN_STATE_DIR:-$root/.state}"
conf="$config_dir/animals.conf"
state="$state_dir/assigned.tsv" # 端末ID <TAB> ペインID <TAB> 動物
lock="$state_dir/lock"

mkdir -p "$config_dir" "$state_dir"
[ -f "$conf" ] || cp "$root/animals.conf.example" "$conf"

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

# 設定の動物を、順番を保ったまま 1 行 1 つにする（重複は先のものを残す）。
animals=$(sed 's/#.*//' "$conf" | tr -s ' \t' '\n\n' | awk 'NF && !seen[$0]++')

touch "$state"
old=$(cat "$state")
new=""
used=""

# 1. いなくなったエージェントのペインから、絵文字付きの名前を消す。
while IFS=$'\t' read -r term pane animal; do
  [ -n "$term" ] || continue
  if ! printf '%s\n' "$live" | cut -f1 | grep -qxF "$term"; then
    "$herdr" pane report-metadata "$pane" --source "$source_id" --clear-display-agent </dev/null >/dev/null 2>&1
  fi
done <<<"$old"

# 2. 動いているエージェントに動物を決めて、名前を送る。
count=$(printf '%s\n' "$animals" | awk 'NF' | wc -l | tr -d ' ')
# 先に、すでに決まっている動物を「使用中」にする（設定から消えた動物は付け直す）。
while IFS=$'\t' read -r term pane agent shown; do
  [ -n "$term" ] || continue
  animal=$(printf '%s\n' "$old" | awk -F'\t' -v t="$term" '$1 == t { print $3; exit }')
  if [ -n "$animal" ] && printf '%s\n' "$animals" | grep -qxF "$animal"; then
    used="$used$animal"$'\n'
  fi
done <<<"$live"

index=0
while IFS=$'\t' read -r term pane agent shown; do
  [ -n "$term" ] || continue
  if [ "$count" -eq 0 ]; then # 動物が 1 つもなければ、元の名前に戻す
    [ -z "$shown" ] || "$herdr" pane report-metadata "$pane" --source "$source_id" --clear-display-agent </dev/null >/dev/null 2>&1
    continue
  fi
  animal=$(printf '%s\n' "$old" | awk -F'\t' -v t="$term" '$1 == t { print $3; exit }')
  if [ -z "$animal" ] || ! printf '%s\n' "$animals" | grep -qxF "$animal"; then
    # 使われていない動物のうち、いちばん先のもの。全部使用中なら先頭から順に重ねる。
    animal=$(printf '%s\n' "$animals" | grep -vxF -f <(printf '%s' "$used") | head -n 1)
    if [ -z "$animal" ]; then
      animal=$(printf '%s\n' "$animals" | sed -n "$((index % count + 1))p")
      index=$((index + 1))
    fi
    used="$used$animal"$'\n'
  fi
  new="$new$term"$'\t'"$pane"$'\t'"$animal"$'\n'
  want="$animal $agent"
  [ "$shown" = "$want" ] || "$herdr" pane report-metadata "$pane" --source "$source_id" --display-agent "$want" </dev/null >/dev/null
done <<<"$live"

printf '%s' "$new" >"$state.tmp" && mv "$state.tmp" "$state"
