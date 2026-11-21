# 🐶 herdr-animals

English | [日本語](README.ja.md)

A [herdr](https://herdr.dev) plugin that adds an animal emoji to each agent name in the sidebar. `claude` and `kiro` become `🐶 claude` and `🐱 kiro`, so you can tell your agents apart at a glance.

- Pick which animals to use, and in what order, in a terminal screen.
- No two running agents share the same animal.
- An agent keeps its animal for as long as it runs.
- When there are not enough animals, 🐾 is shown instead.

## Requirements

- herdr 0.9.5 or later
- bash and [jq](https://jqlang.org/) (`brew install jq`)
- macOS or Linux

## Install

```sh
git clone https://github.com/asaty94/herdr-animals
herdr plugin link ./herdr-animals
herdr plugin action invoke asaty94.animals.refresh
```

The last line adds animals to the agents that are already running. If you skip it, they get animals the next time an agent's status changes.

If you have customized the sidebar rows (`ui.sidebar.agents.rows` in `~/.config/herdr/config.toml`), keep `"agent"` in the list. The animal appears where `agent` is shown.

## Pick animals

```sh
herdr plugin action invoke asaty94.animals.pick
```

A popup opens with a list of animals. Only checked animals are used, and the ones nearer the top are used first. The screen text is in Japanese; the keys are:

| Key | Action |
|---|---|
| `↑` `↓` (`k` `j`) | Move |
| `space` | Check or uncheck. A newly checked animal goes to the end of the checked ones |
| `t` | Move to the top (use this animal first) |
| `K` `J` | Move up or down by one |
| `enter` | Save and close |
| `q` `esc` | Close without saving |

If you use it often, bind a key in `~/.config/herdr/config.toml`. herdr does not let plugins register keys, so you need to add it yourself.

```toml
[[keys.command]]
key = "prefix+shift+a"
type = "plugin_action"
command = "asaty94.animals.pick"
description = "Pick animals"
```

```sh
herdr server reload-config
```

## How animals are assigned

- A new agent gets the highest animal in your list that no running agent is using.
- When an agent exits, its animal becomes free for the next agent.
- Reordering the list does not change animals that are already assigned. Only agents whose animal you unchecked get a new one.
- When every animal is in use, the agent gets 🐾. It keeps 🐾 even after an animal becomes free. Saving in the pick screen gives free animals to agents showing 🐾.
- If you uncheck every animal, agent names go back to normal.

## Configuration file

Your choices are saved in `animals.conf`. You can edit it by hand, and you can add emoji that are not in the list.

```sh
open "$(herdr plugin config-dir asaty94.animals)/animals.conf"
```

```
🦊 🐼 🐶
overflow=🐾
```

`overflow` is the mark shown when there are not enough animals. After editing the file by hand, run `refresh` or wait until an agent's status changes.

## Uninstall

In the pick screen, uncheck every animal and save so that agent names go back to normal. Then unlink the plugin.

```sh
herdr plugin unlink asaty94.animals
```

## Development

| File | Role |
|---|---|
| `herdr-plugin.toml` | What runs and when |
| `animals.sh` | Assigns animals |
| `picker.sh` | The pick screen |
| `lib.sh` | Reads and writes the configuration |
| `catalog.txt` | Animals shown in the pick screen |

Assignment and the pick screen are tested with a stand-in for herdr.

```sh
bash tests/run.sh
```
