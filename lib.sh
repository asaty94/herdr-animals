# animals.sh と picker.sh が共に使う、場所と設定の読み書き。
herdr="${HERDR_BIN_PATH:-herdr}"
plugin_id="${HERDR_PLUGIN_ID:-asaty94.animals}"
root="${HERDR_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
config_dir="${HERDR_PLUGIN_CONFIG_DIR:-$root/.config}"
state_dir="${HERDR_PLUGIN_STATE_DIR:-$root/.state}"
conf="$config_dir/animals.conf"
default_overflow="🐾"
default_count=12 # 初めて使うときに選んでおく動物の数（catalog.txt の先頭から）

# 絵文字の並びを、順番を保ったまま 1 行 1 つにする（重複は先のものを残す）。
one_per_line() { sed -e 's/#.*//' -e '/^overflow *=/d' | tr -s ' \t' '\n\n' | awk 'NF && !seen[$0]++'; }

catalog() { one_per_line <"$root/catalog.txt"; }

# 設定を書く。引数: 動物が足りないときの印、動物（優先順）...
write_conf() {
  local overflow=$1
  shift
  mkdir -p "$config_dir"
  {
    echo "# 使う動物。先に書いたものから使う。空白か改行で区切る。# から行末まではコメント。"
    echo "# 「herdr plugin action invoke $plugin_id.pick」の画面で保存すると、このファイルは書き直される。"
    echo "$*"
    echo
    echo "# 動物が足りないときに付ける印。"
    echo "overflow=$overflow"
  } >"$conf.tmp" && mv "$conf.tmp" "$conf"
}

ensure_conf() {
  [ -f "$conf" ] && return
  # shellcheck disable=SC2046
  write_conf "$default_overflow" $(catalog | head -n "$default_count")
}

read_animals() { one_per_line <"$conf"; }

read_overflow() {
  local value
  value=$(sed -n 's/^overflow *= *//p' "$conf" | sed -e 's/#.*//' -e 's/[[:space:]]*$//' | head -n 1)
  echo "${value:-$default_overflow}"
}
