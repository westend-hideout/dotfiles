#!/bin/sh
# Choose optional CLI tools, languages and GUI apps for this machine.
# The choice is saved outside the repository and reused on later runs;
# pass --reconfigure to install.sh (DOTFILES_RECONFIGURE=1) to choose again.
set -eu
# shellcheck source=../lib/common.sh
. "$(dirname -- "$0")/../lib/common.sh"

if [ -f "$DOTFILES_SELECTION" ] && [ "${DOTFILES_RECONFIGURE:-0}" != 1 ]; then
    ok "options: $(selected_options | tr '\n' ' ')"
    finish
fi

if is_check; then
    if [ -f "$DOTFILES_SELECTION" ]; then
        differs "options will be chosen again (current: $(selected_options | tr '\n' ' '))"
    else
        differs "options have not been chosen yet"
    fi
    finish
fi

[ -t 0 ] && [ -t 1 ] || die "run install.sh in a terminal to choose options"
command -v gum >/dev/null 2>&1 || brew install gum

# Build "id  group  label" lines as gum arguments, preselecting the saved choice.
set --
preselected=""
while IFS="$(printf '\t')" read -r id group label; do
    case $id in '' | '#'*) continue ;; esac
    item=$(printf '%-16s %-5s %s' "$id" "$group" "$label")
    set -- "$@" "$item"
    if is_selected "$id"; then
        preselected="${preselected:+$preselected,}$item"
    fi
done <"$DOTFILES_CATALOG"

chosen=$(gum choose --no-limit --height 30 \
    --header "Choose what to install (x or tab: toggle, enter: confirm)" \
    --selected "$preselected" "$@") || die "selection cancelled"

mkdir -p "$DOTFILES_STATE_DIR"
printf '%s\n' "$chosen" | awk 'NF { print $1 }' >"$DOTFILES_SELECTION"
done_ "saved options to $DOTFILES_SELECTION: $(selected_options | tr '\n' ' ')"

finish
