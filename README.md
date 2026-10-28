# dotfiles

macOS の開発環境を作るためのリポジトリです。`./install.sh` を実行すると、Homebrew とツール、fish・Neovim・Vim・Ghostty の設定、言語ランタイム(mise)までを揃えます。

何度実行しても大丈夫です。揃っているものはスキップし、変更する前には何が変わるかを表示して確認します。

## 新しい Mac でのセットアップ

```sh
# 1. Homebrew を入れる(Xcode Command Line Tools と git も一緒に入ります)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. このリポジトリを取ってくる(置き場所はどこでも構いません)
git clone https://github.com/westend-hideout/dotfiles.git ~/my_work/dotfiles

# 3. セットアップする
~/my_work/dotfiles/install.sh
```

`install.sh` も、Homebrew がなければ入れるようになっています。ただ、2 の `git clone` には git が必要なので、先に 1 を実行してください。

途中で聞かれるのは次のものです。

- 変更してよいかの確認
- 入れるツールやアプリの選択(初回だけ)
- 既存の設定ファイルを上書きするか
- ログインシェルを fish に変えるときのパスワード

## 使い方

```sh
./install.sh                  # 差分を表示し、確認してから全部の手順を適用する
./install.sh --check          # 差分を表示するだけ。何も変更しない
./install.sh files mise       # 指定した手順だけ実行する
./install.sh --reconfigure    # 入れるツールやアプリを選び直す
./install.sh --yes            # 最初の確認を飛ばす(設定ファイルの上書きは飛ばさずに聞く)
```

`--check` は、今の Mac とリポジトリの違いを見るのに使えます。

- 足りないパッケージ、古いパッケージ
- 内容が違う設定ファイル
- **入っているのにどの Brewfile にもないパッケージ**(手で `brew install` したもの)

## 手順

`install.sh` は次の順に実行します。どの手順も、揃っていればスキップします。

| 手順 | やること |
|---|---|
| `homebrew` | Homebrew がなければ入れる |
| `select` | 入れるツールやアプリを選ぶ。選んだ内容は `~/.config/dotfiles/options` に保存し、2 回目からは聞かない |
| `packages` | Core の Brewfile と、選んだものの Brewfile を `brew bundle` で入れる。古いものは更新する |
| `files` | 設定ファイルをコピーする(下の「設定ファイル」) |
| `mise` | 選んだ言語のバージョンを入れる |
| `shell` | fish をログインシェルにする |
| `editor` | vim-plug を入れて、Vim / Neovim のプラグインを入れる |

## 入れるもの

| グループ | 中身 | 扱い |
|---|---|---|
| Core | fish・git・gh・ripgrep・fd・jq・ast-grep・yq(Go 版)・Neovim・ctags・mise・gum | 必ず入れる |
| Work | AWS CLI・Spectral・OrbStack・Docker Desktop・Sequel Ace・Slack・Zoom | 選ぶ。職場によって要らないもの |
| Lang | Ruby・Node.js(+ pnpm・yarn)・Python・Java・Deno | 選ぶ。mise で入れる |
| CLI | ccusage | 選ぶ |
| App | Ghostty・iTerm2・VS Code・Chrome・Brave・1Password・DeepL・Claude・ChatGPT | 選ぶ |

- Core は `brew/Brewfile` に書いてあります
- 選べるものの一覧は `options/catalog.tsv` です
- 選択を外しても、入っているものをアンインストールはしません

## 設定ファイル

| リポジトリ | コピー先 |
|---|---|
| `fish/config.fish` | `~/.config/fish/config.fish` |
| `nvim/init.vim` | `~/.config/nvim/init.vim` |
| `.vimrc` | `~/.vimrc` |
| `colors/one.vim` | `~/.config/nvim/colors/one.vim` と `~/.vim/colors/one.vim` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `options/<言語>.mise.toml` | `~/.config/mise/conf.d/<言語>.toml`(選んだ言語だけ) |

コピーしたファイルの 1 行目には、どこから来たかの印が入ります。

```
# westend-hideout/dotfiles: fish/config.fish [copied 2026-10-28 sha256:6b59d21644c6]
```

再実行したときは、この印を見て次のように動きます。

| 状態 | 動き |
|---|---|
| コピー先にファイルがない | コピーする |
| どちらも変わっていない | 何もしない |
| リポジトリ側だけ変わった | 聞かずに更新する |
| コピー先だけ変えた | 何もしない(そのまま残す) |
| 両方変わった、または印がない(元からあったファイル) | 差分を表示して「バックアップして上書き / スキップ」を選ぶ |

上書きする前のファイルは `~/.dotfiles-backup/<日時>/` に退避します。

### 設定を変えたいとき

共通の設定は、**リポジトリ側を編集してから `./install.sh files` を実行**します。コピー先を直接編集しても、リポジトリには戻りません。

## マシン固有の設定

職場ごとの環境変数・PATH・認証情報など、マシンごとに違う設定はこのリポジトリに入れません。

- fish: `~/.config/fish/local.fish` に書きます。`config.fish` の最後に読み込まれ、`install.sh` がこのファイルに触ることはありません
- Git: `~/.gitconfig`

`config.fish` に直接書くと、次にリポジトリ側が変わったときに上書きするかを聞かれます。

## 言語のバージョン

言語ランタイムは [mise](https://mise.jdx.dev/) で管理します。

- 普段使うバージョンは `options/<言語>.mise.toml` に書いてあります
- プロジェクトに `.ruby-version`・`.node-version`・`.python-version`・`mise.toml` があれば、そちらが優先されます
