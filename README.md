# 🐶 herdr-animals

[herdr](https://herdr.dev) のサイドバーに出るエージェント名へ、動物の絵文字を付けるプラグイン。`claude` や `kiro` が `🐶 claude`、`🐱 kiro` になり、エージェントを見分けやすくなる。

- 使う動物と優先順位を、ターミナルの画面で選ぶ。
- 動いているエージェントどうしで動物は重ならない。
- エージェントが動いている間、動物は変わらない。
- 動物が足りなくなったら、動物の代わりに 🐾 を付ける。

## 必要なもの

- herdr 0.9.5 以上
- bash と [jq](https://jqlang.org/)（`brew install jq`）
- macOS か Linux

## 入れ方

```sh
git clone https://github.com/asaty94/herdr-animals
herdr plugin link ./herdr-animals
herdr plugin action invoke asaty94.animals.refresh
```

最後の行は、いま動いているエージェントにすぐ動物を付けるためのもの。実行しなくても、次にエージェントの状態が変わったときに付く。

サイドバーの行の設定（`~/.config/herdr/config.toml` の `ui.sidebar.agents.rows`）を変えている場合は、`"agent"` を残しておく。動物はこの `agent` の位置に出る。

## 動物を選ぶ

```sh
herdr plugin action invoke asaty94.animals.pick
```

動物の一覧がポップアップで開く。チェックを付けた動物だけを使い、上にあるものから先に付ける。

| キー | 動き |
|---|---|
| `↑` `↓`（`k` `j`） | 移動 |
| `space` | チェックを付ける・外す。付けた動物は、チェック済みの末尾に入る |
| `t` | 先頭へ移す（いちばん先に使う動物にする） |
| `K` `J` | 1 つ上へ・下へ |
| `enter` | 保存して閉じる |
| `q` `esc` | 保存せずに閉じる |

よく使うなら、`~/.config/herdr/config.toml` にキーを割り当てる。herdr はプラグインからキーを登録できないため、手で書く。

```toml
[[keys.command]]
key = "prefix+shift+a"
type = "plugin_action"
command = "asaty94.animals.pick"
description = "動物を選ぶ"
```

```sh
herdr server reload-config
```

## 動物の付き方

- 新しいエージェントには、いま誰も使っていない動物のうち、いちばん上のものが付く。
- エージェントが終わると、その動物は空き、次のエージェントに使える。
- 順番を入れ替えても、すでに付いている動物は変わらない。チェックを外した動物を使っているエージェントだけ、付け直す。
- 動物がすべて使われているときは 🐾 が付く。あとで動物が空いても 🐾 のまま。画面で動物を選び直して保存すると、🐾 のエージェントにも空いている動物が付く。
- チェックをすべて外すと、元の名前に戻る。

## 設定ファイル

選んだ内容は `animals.conf` に保存される。手で書き換えてもよい。一覧にない絵文字も、ここに書けば使える。

```sh
open "$(herdr plugin config-dir asaty94.animals)/animals.conf"
```

```
🦊 🐼 🐶
overflow=🐾
```

`overflow` は、動物が足りないときに付ける印。手で書き換えたあとは、`refresh` を実行するか、次にエージェントの状態が変わるのを待つ。

## やめ方

動物を選ぶ画面でチェックをすべて外して保存し、名前を元に戻してから外す。

```sh
herdr plugin unlink asaty94.animals
```

## 開発

| ファイル | 役割 |
|---|---|
| `herdr-plugin.toml` | いつ何を動かすかの定義 |
| `animals.sh` | 動物の割り当て |
| `picker.sh` | 動物を選ぶ画面 |
| `lib.sh` | 設定の読み書き |
| `catalog.txt` | 画面に出す動物の一覧 |

割り当てと画面の動きは、herdr の代役を使ったテストで確かめる。

```sh
bash tests/run.sh
```

## ライセンス

[MIT](LICENSE)
