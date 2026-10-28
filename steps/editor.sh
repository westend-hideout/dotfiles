#!/bin/sh
# Install vim-plug and the Neovim plugins listed in nvim/init.vim.
# PlugInstall only installs missing plugins, so it is safe to run every time.
set -eu
# shellcheck source=../lib/common.sh
. "$(dirname -- "$0")/../lib/common.sh"

PLUG_URL=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
PLUG_PATH="$HOME/.local/share/nvim/site/autoload/plug.vim"
PLUGGED_DIR="$HOME/.config/nvim/plugged"

if ! command -v nvim >/dev/null 2>&1; then
    if is_check; then
        differs "nvim is not installed"
    else
        warn "nvim is not installed, skipped"
    fi
    finish
fi

if is_check; then
    if [ ! -f "$PLUG_PATH" ]; then
        differs "$PLUG_PATH does not exist"
    elif [ -z "$(ls -A "$PLUGGED_DIR" 2>/dev/null)" ]; then
        differs "nvim plugins are not installed in $PLUGGED_DIR"
    else
        ok "nvim plugins"
    fi
    finish
fi

if [ ! -f "$PLUG_PATH" ]; then
    curl -fLo "$PLUG_PATH" --create-dirs "$PLUG_URL"
    done_ "installed $PLUG_PATH"
fi
nvim --headless +PlugInstall +qall
done_ "nvim plugins"

finish
