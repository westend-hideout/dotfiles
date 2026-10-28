# Shared helpers sourced by install.sh and steps/*.sh.
# Each step runs in DOTFILES_MODE=apply (make changes) or check (report only).
# In check mode a step exits 3 when the machine differs from this repository.

DOTFILES_ROOT=${DOTFILES_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}
DOTFILES_MODE=${DOTFILES_MODE:-apply}
DOTFILES_STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
DOTFILES_SELECTION="$DOTFILES_STATE_DIR/options"
DOTFILES_CATALOG="$DOTFILES_ROOT/options/catalog.tsv"
drift=0

# Homebrew is not on PATH right after installation or in a non-login shell.
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$brew_bin" ]; then
        eval "$("$brew_bin" shellenv)"
        break
    fi
done

ok() { printf '  ok: %s\n' "$*"; }
done_() { printf '  done: %s\n' "$*"; }
warn() { printf '  warn: %s\n' "$*" >&2; }
# Something worth knowing that is not a difference to apply.
note() { printf '  note: %s\n' "$*"; }
die() { printf '  error: %s\n' "$*" >&2; exit 2; }

# Used in check mode to report something apply would change.
differs() {
    printf '  differs: %s\n' "$*"
    drift=1
}

is_check() { [ "$DOTFILES_MODE" = check ]; }

# Ask a yes/no question on the terminal. The default, and the answer when
# there is no terminal, is no.
confirm() {
    [ -t 0 ] && [ -t 1 ] || return 1
    printf '%s [y/N] ' "$1"
    read -r answer || return 1
    case $answer in [yY] | [yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

# Ask with header $1 whether to keep things as they are ($2) or replace them ($3).
# Returns 0 only when $3 is picked; the default, and the answer when there is
# no terminal, is to keep.
choose_replace() {
    [ -t 0 ] && [ -t 1 ] || return 1
    if command -v gum >/dev/null 2>&1; then
        answer=$(gum choose --header "$1" "$2" "$3") || return 1
        [ "$answer" = "$3" ]
    else
        confirm "$1 $3?"
    fi
}

finish() {
    if is_check && [ "$drift" -ne 0 ]; then
        exit 3
    fi
    exit 0
}

# Print the ids of the options chosen on this machine, one per line.
selected_options() {
    if [ -f "$DOTFILES_SELECTION" ]; then
        grep -v '^[[:space:]]*$' "$DOTFILES_SELECTION" || true
    fi
}

is_selected() {
    selected_options | grep -qx "$1"
}
