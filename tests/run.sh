#!/bin/bash
# animals.sh の割り当てを、herdr の代役（tests/fake-herdr）で確かめる。使い方: bash tests/run.sh
cd "$(dirname "$0")/.." || exit 1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export FAKE_DIR="$tmp/fake" HERDR_BIN_PATH="$PWD/tests/fake-herdr" HERDR_PLUGIN_ROOT="$PWD"
export HERDR_PLUGIN_CONFIG_DIR="$tmp/config" HERDR_PLUGIN_STATE_DIR="$tmp/state" HERDR_PLUGIN_ID=test.animals
mkdir -p "$FAKE_DIR/shown" "$HERDR_PLUGIN_CONFIG_DIR"
fail=0

agents() { printf '%b' "$1" >"$FAKE_DIR/agents.tsv"; }
run() { : >"$FAKE_DIR/calls"; bash animals.sh; }
shown() { cat "$FAKE_DIR/shown/$1" 2>/dev/null; }
check() { # 説明 実際 期待
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "NG   $1: 「$2」（期待は「$3」）"; fail=1; fi
}

printf '# コメント\n🐶 🐱\n🐼 # 行末コメント\n🐶\n' >"$HERDR_PLUGIN_CONFIG_DIR/animals.conf"

agents 't1\tp1\tclaude\nt2\tp2\tkiro\n'
run
check "1 番目のエージェントに 1 番目の動物" "$(shown p1)" "🐶 claude"
check "2 番目のエージェントに 2 番目の動物" "$(shown p2)" "🐱 kiro"

run
check "変化がなければ何も送らない" "$(cat "$FAKE_DIR/calls")" ""

agents 't2\tp2\tkiro\nt3\tp3\tcodex\n'
run
check "終わったエージェントのペインから名前を消す" "$(shown p1)" ""
check "動いているエージェントの動物は変わらない" "$(shown p2)" "🐱 kiro"
check "空いた動物のうち、いちばん先のものを使う" "$(shown p3)" "🐶 codex"

agents 't2\tp2\tclaude\nt3\tp3\tcodex\n'
run
check "エージェントの種類が変わったら、同じ動物のまま名前を直す" "$(shown p2)" "🐱 claude"

agents 't2\tp2\tclaude\nt3\tp3\tcodex\nt4\tp4\tkiro\nt5\tp5\tkiro\nt6\tp6\tkiro\n'
run
check "3 番目の動物" "$(shown p4)" "🐼 kiro"
check "動物が足りなければ先頭から重ねる (1)" "$(shown p5)" "🐶 kiro"
check "動物が足りなければ先頭から重ねる (2)" "$(shown p6)" "🐱 kiro"

touch "$FAKE_DIR/fail"
run
rm "$FAKE_DIR/fail"
check "一覧を取れないときは何も変えない" "$(cat "$FAKE_DIR/calls")$(shown p2)" "🐱 claude"

touch "$FAKE_DIR/broken"
run
rm "$FAKE_DIR/broken"
check "一覧の形が違うときも何も変えない" "$(cat "$FAKE_DIR/calls")$(shown p2)" "🐱 claude"

agents 't2\tp2\tclaude\nt3\tp3\tcodex\n'
printf '🦊\n🐶\n' >"$HERDR_PLUGIN_CONFIG_DIR/animals.conf"
run
check "設定に残った動物はそのまま" "$(shown p3)" "🐶 codex"
check "設定から消えた動物は、順番に従って付け直す" "$(shown p2)" "🦊 claude"

: >"$HERDR_PLUGIN_CONFIG_DIR/animals.conf"
run
check "動物が空なら元の名前に戻す" "$(shown p2)$(shown p3)" ""

rm "$HERDR_PLUGIN_CONFIG_DIR/animals.conf"
agents 't7\tp7\tclaude\n'
run
check "設定がなければ見本から作る" "$(shown p7)" "🐶 claude"

exit $fail
