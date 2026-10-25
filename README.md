# dotfiles

macOS で使っている fish・Neovim・Vim・Ghostty の設定と、Homebrew で入れるツールの一覧です。

## 構成

| ファイル | リンク先 | 内容 |
|---|---|---|
| `fish/config.fish` | `~/.config/fish/config.fish` | fish の設定とエイリアス |
| `nvim/init.vim` | `~/.config/nvim/init.vim` | Neovim の設定 |
| `.vimrc` | `~/.vimrc` | Vim の設定 |
| `colors/one.vim` | `~/.config/nvim/colors/one.vim`<br>`~/.vim/colors/one.vim` | Vim / Neovim 共通のカラースキーム |
| `ghostty/config` | `~/.config/ghostty/config` | Ghostty の設定 |
| `Brewfile` | - | CLI ツールの一覧 |
| `Brewfile.work` | - | 仕事用マシン向けの GUI アプリの一覧 |

## セットアップ

[Homebrew](https://brew.sh/ja/) が入っていることが前提です。

```sh
brew bundle --file=Brewfile
./setup.sh
```

`setup.sh` は設定ファイルを上の表のリンク先にシンボリックリンクします。リンク先にファイルがある場合は、`~/.dotfiles-backup/<日時>/` に退避してからリンクします。アプリのインストールはしません。

仕事用マシンで GUI アプリも入れる場合は、`Brewfile.work` を別に適用します。

```sh
brew bundle --file=Brewfile.work
```

### エディタのプラグイン

プラグインは [vim-plug](https://github.com/junegunn/vim-plug) で管理しています。vim-plug がなくてもエディタ自体は起動します。

```sh
# Neovim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim +PlugInstall +qall

# Vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall
```

## マシン固有の設定

PATH・認証情報・Git のユーザー情報など、マシンごとに違う設定はこのリポジトリに入れません。

- fish: `~/.config/fish/local.fish`(`config.fish` の最後に読み込まれます)
- Git: `~/.gitconfig`
