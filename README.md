# herdr-animals

[herdr](https://herdr.dev) のサイドバーに出るエージェント名へ、動物の絵文字を付けるプラグイン。`claude` や `kiro` が `🐶 claude`、`🐱 kiro` になり、エージェントを見分けやすくなる。

- 動物は、あらかじめ選んだものを、決めた順番で付ける。
- 動いているエージェントどうしで動物は重ならない（動物の数が足りる間）。
- エージェントが動いている間、動物は変わらない。

## 必要なもの

herdr 0.9.5 以上、bash、[jq](https://jqlang.org/)（`brew install jq`）。macOS と Linux。

## 入れ方

```sh
git clone https://github.com/asaty94/herdr-animals
herdr plugin link ./herdr-animals
```

入れた直後は、次にエージェントの状態が変わったときに動物が付く。すぐ付けるには次を実行する。

```sh
herdr plugin action invoke asaty94.animals.refresh
```

サイドバーの行の設定（`~/.config/herdr/config.toml` の `ui.sidebar.agents.rows`）を変えている場合は、`"agent"` を残しておく。動物はこの `agent` の位置に出る。

## 動物と順番を決める

設定ファイルを開く。

```sh
open "$(herdr plugin config-dir asaty94.animals)/animals.conf"
```

付けたい順番に絵文字を書く。先に書いた動物から使う。

```
# 空白か改行で区切る。# から行末まではコメント。
🐶 🐱 🐼 🦊 🐰 🐻 🐯 🦁 🐸 🐵 🐧 🐨
```

変更は、次にエージェントの状態が変わったとき、または上の `refresh` を実行したときに反映する。動物以外の絵文字や文字も使える。

## やめ方

```sh
herdr plugin unlink asaty94.animals
```

付いたままの動物は、設定ファイルを空にして `refresh` を実行してから外すと消える。

## 開発

細かな決まりは [specification/plugin.md](specification/plugin.md) にある。割り当てのテストは、herdr の代役を使って動かす。

```sh
bash tests/run.sh
```
