# dotfiles

新しいマシンでも使い慣れた fish、Neovim、Ghostty の設定を再現するための個人設定です。設定ファイルとアプリ一覧を分け、端末固有の値は各マシンに残します。

## 管理しているもの

- `fish/config.fish`: fish の基本設定、`v` → Neovim のエイリアス。rbenv と Homebrew は存在する場合だけ初期化します。
- `nvim/init.vim` と `colors/one.vim`: Neovim の設定と共通カラースキーム。
- `.vimrc`: Vim 用の既存設定。
- `ghostty/config`: Ghostty の表示・操作設定。
- `Brewfile`: この Mac で Homebrew から直接入れた CLI ツールと Universal Ctags の一覧。
- `Brewfile.work`: 会社 PC 向け GUI アプリ一覧。
- `setup.sh`: 設定ファイルをホームへリンクします。アプリはインストールしません。

## セットアップ

Git と Homebrew を利用できる macOS では、リポジトリを clone した後、必要なアプリと設定を別々に適用します。

```sh
git clone git@github.com:nishihata/dotfiles.git ~/work/my_documents/dotfiles
cd ~/work/my_documents/dotfiles
brew bundle --file=Brewfile
./setup.sh
```

`Brewfile` は現在の Mac で直接導入した CLI ツールを記録しています。ctags は Homebrew の `universal-ctags` に統一しています。Ghostty は別の `Brewfile.work` にあります。fish のエイリアス `v` は Neovim がインストールされている場合に有効になります。

## 会社 PC 向けアプリ

`Brewfile.work` は会社 PC で使いたい GUI アプリの一覧です。会社のソフトウェア導入ルールを確認し、許可されている場合だけ適用してください。

```sh
brew bundle --file=Brewfile.work
```

会社の管理ツールやセルフサービス経由で導入する場合は、Brewfile をアプリ一覧として参照し、会社指定の方法を使ってください。個人用アプリはこの一覧に混ぜず、必要になった時に別の Brewfile に分けます。

## Neovim プラグイン

vim-plug を利用する場合はインストール後にプラグインを取得します。プラグインマネージャーがない場合も Neovim 自体は起動できます。

```sh
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim +PlugInstall +qall
```

## ローカル専用設定

- fish: `~/.config/fish/local.fish`
- Git の名前とメールアドレス: `~/.gitconfig`

AWS profile、端末固有の PATH、認証情報などは共有設定に書かず、ローカル専用ファイルに置いてください。`setup.sh` は既存の設定ファイルを `~/.dotfiles-backup/` に退避してからリンクします。

<!-- 芝の動作確認用の変更(README 一新時に削除予定) -->
