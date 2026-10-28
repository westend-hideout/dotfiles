# dotfiles

macOS の開発環境を作るためのリポジトリです。`./install.sh` を実行すると、Homebrew で入れるツール、fish・Neovim・Ghostty の設定、言語ランタイム(mise)までを揃えます。

何度実行しても大丈夫です。揃っているものはスキップし、変更する前には何が変わるかを表示して確認します。

## 新しい Mac でのセットアップ

1. **Homebrew を入れる**

   [Homebrew の公式サイト](https://brew.sh/ja/)に載っているインストール用のコマンドを実行します。Xcode Command Line Tools と git も一緒に入ります。

2. **このリポジトリを取ってきて、セットアップする**

   ```sh
   # 置き場所はどこでも構いません
   git clone https://github.com/westend-hideout/dotfiles.git ~/my_work/dotfiles
   ~/my_work/dotfiles/install.sh
   ```

`install.sh` は Homebrew を入れません。Homebrew がないときは、公式サイトの URL を表示して止まります。

途中で聞かれるのは次のものです。

- 変更してよいかの確認
- 入れるツールやアプリの選択(初回だけ)。`x` か Tab で選んで、Enter で決定します(スペースでは選べません)
- Homebrew 以外で入れたアプリを、ゴミ箱に移して Homebrew で入れ直すか
- 既存の設定ファイルを上書きするか
- ログインシェルを fish に変えるときのパスワード

どの確認も、何も選ばずに Enter を押すと「そのまま残す」になります。

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
| `homebrew` | Homebrew が入っているか確かめる。なければ公式サイトの URL を表示して止まる |
| `select` | 入れるツールやアプリを選ぶ。選んだ内容は `~/.config/dotfiles/options` に保存し、2 回目からは聞かない |
| `packages` | Core の Brewfile と、選んだものの Brewfile を `brew bundle` で入れる。古いものは更新する(下の「すでに入っているアプリ」) |
| `files` | 設定ファイルをコピーする(下の「設定ファイル」) |
| `mise` | 選んだ言語のバージョンを入れる |
| `shell` | fish をログインシェルにする |
| `editor` | vim-plug を入れて、Neovim のプラグインを入れる |

## 入れるもの

| グループ | 中身 | 扱い |
|---|---|---|
| Core | fish・git・gh・delta・gitleaks・ripgrep・fd・jq・ast-grep・yq(Go 版)・Neovim・ctags・shellcheck・mise・gum | 必ず入れる |
| Work | AWS CLI・1Password CLI・Spectral・OrbStack・Docker Desktop・Sequel Ace・Slack・Zoom | 選ぶ。職場によって要らないもの |
| Lang | Ruby・Node.js(+ pnpm・yarn)・Python(+ uv)・Java・Deno | 選ぶ。mise で入れる |
| App | Ghostty・VS Code・Chrome・Brave・1Password・DeepL・ChatGPT | 選ぶ |

Claude Code と Claude のデスクトップアプリは、公式のインストーラで入れます(自動で更新されます)。

- Core は `brew/Brewfile` に書いてあります
- 選べるものの一覧は `options/catalog.tsv` です
- 選択を外しても、入っているものをアンインストールはしません

### すでに入っているアプリ

選んだアプリが `/Applications` にすでにあるときは、入れ方によって扱いが変わります。

| 入れ方 | 動き |
|---|---|
| Homebrew で入れた | 古ければ更新する |
| Homebrew 以外(公式サイトなど)で入れた | バージョンを表示して、「ゴミ箱に移して Homebrew で入れ直す / そのまま残す」を選ぶ。入れ直すと、以後は Homebrew が更新する |
| App Store で入れた | 触らずにスキップする。App Store で更新してください |

入れ直すときに動かすのはアプリ本体だけで、`~/Library` の下にあるアプリの設定やデータには触りません。

### CLI ツール

Core(必ず入るもの):

| ツール | 何をするか | 例 |
|---|---|---|
| fish | シェル | `fish_config`(ブラウザで設定画面を開く) |
| git | バージョン管理 | `git switch -c feat/x` |
| gh | GitHub を操作する(PR・Issue など) | `gh pr create --draft` |
| delta | `git diff` を色付きで見やすく表示する | `git diff \| delta` |
| gitleaks | API キーなどの秘密情報が入っていないか調べる | `gitleaks git`(リポジトリの履歴を調べる) |
| ripgrep | ファイルの中身を高速に検索する | `rg -n 'TODO' app/` |
| fd | ファイル名で高速に検索する | `fd -e rb user` |
| ast-grep | コードを構文で検索・置換する | `ast-grep -p 'console.log($A)' -l ts` |
| jq | JSON を取り出す・加工する | `jq '.dependencies' package.json` |
| yq | YAML を取り出す・加工する(Go 版) | `yq '.services \| keys' compose.yml` |
| Neovim | エディタ | `nvim file.rb`(エイリアス `v`・`vi`・`vim`) |
| ctags | タグファイルを作る(Neovim のタグジャンプ用) | `ctags -R .` |
| shellcheck | シェルスクリプトの間違いを見つける | `shellcheck install.sh` |
| mise | 言語ランタイムのバージョンを管理する | `mise use node@20`(今のディレクトリで Node 20 を使う) |
| gum | シェルスクリプトで選択画面や確認を出す | `gum choose a b c` |

選択式:

| ツール | グループ | 何をするか | 例 |
|---|---|---|---|
| AWS CLI | Work | AWS を操作する | `aws sts get-caller-identity`(今の認証情報を確かめる) |
| 1Password CLI | Work | 1Password から秘密情報を取り出す | `op read 'op://Private/GitHub/token'` |
| Spectral | Work | OpenAPI の定義をチェックする | `spectral lint openapi.yaml`(ルールの `.spectral.yaml` が必要) |

## 設定ファイル

| リポジトリ | コピー先 |
|---|---|
| `fish/config.fish` | `~/.config/fish/config.fish` |
| `fish/conf.d/ghostty-theme.fish` | `~/.config/fish/conf.d/ghostty-theme.fish`(リポジトリの `.ghostty-theme` に合わせて Ghostty のタイトルと色を変える) |
| `nvim/init.vim` | `~/.config/nvim/init.vim` |
| `colors/one.vim` | `~/.config/nvim/colors/one.vim` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `mise/global.toml` | `~/.config/mise/config.toml`(リポジトリの中で mise がプロジェクトの設定として読まないよう、別の名前にしている) |
| `uv/uv.toml` | `~/.config/uv/uv.toml` |
| `options/<言語>.mise.toml` | `~/.config/mise/conf.d/<言語>.toml`(選んだ言語だけ) |

fish の色とプロンプトは、fish に入っているテーマ「ayu Mirage」とサンプルプロンプト「nim」を、`config.fish` で名前を指定して読み込んでいます。変えたいときは `fish_config theme list` / `fish_config prompt list` で名前を探して、`config.fish` を書き換えます。

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
