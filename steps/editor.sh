#!/bin/sh
# Install vim-plug and the plugins listed in .vimrc / nvim/init.vim.
# PlugInstall only installs missing plugins, so it is safe to run every time.
set -eu
# shellcheck source=../lib/common.sh
. "$(dirname -- "$0")/../lib/common.sh"

PLUG_URL=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

setup_editor() {
    editor=$1
    plug_path=$2
    plugged_dir=$3

    if ! command -v "$editor" >/dev/null 2>&1; then
        if is_check; then
            differs "$editor is not installed"
        else
            warn "$editor is not installed, skipped"
        fi
        return
    fi

    if is_check; then
        if [ ! -f "$plug_path" ]; then
            differs "$plug_path does not exist"
        elif [ -z "$(ls -A "$plugged_dir" 2>/dev/null)" ]; then
            differs "$editor plugins are not installed in $plugged_dir"
        else
            ok "$editor plugins"
        fi
        return
    fi

    if [ ! -f "$plug_path" ]; then
        curl -fLo "$plug_path" --create-dirs "$PLUG_URL"
        done_ "installed $plug_path"
    fi
    case $editor in
        nvim) nvim --headless +PlugInstall +qall ;;
        vim) vim -E -s -u "$HOME/.vimrc" +PlugInstall +qall </dev/null || true ;;
    esac
    done_ "$editor plugins"
}

setup_editor nvim "$HOME/.local/share/nvim/site/autoload/plug.vim" "$HOME/.config/nvim/plugged"
setup_editor vim "$HOME/.vim/autoload/plug.vim" "$HOME/.vim/plugged"

finish
