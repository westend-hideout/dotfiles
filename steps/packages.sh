#!/bin/sh
# Install the base Brewfile and the Brewfiles of the chosen options.
# brew bundle installs what is missing, upgrades what is outdated and adopts
# apps installed by hand. Deselected options are never uninstalled.
set -eu
# shellcheck source=../lib/common.sh
. "$(dirname -- "$0")/../lib/common.sh"

command -v brew >/dev/null 2>&1 || {
    is_check && { differs "Homebrew is not installed"; finish; }
    die "Homebrew is not installed (run the homebrew step first)"
}

# Formulae replaced by one in a Brewfile that installs the same command.
# brew bundle cannot install the new one while the old one is installed,
# and uninstalling is left to the user. Format: "old new".
REPLACED="python-yq yq"

check_replaced() {
    # A here-document keeps the loop in this shell so differs and die take effect.
    while read -r old new; do
        brew list --formula "$old" >/dev/null 2>&1 || continue
        if is_check; then
            differs "$old is installed and conflicts with $new (run: brew uninstall $old)"
        else
            die "$old conflicts with $new in the Brewfile. Run 'brew uninstall $old' and rerun."
        fi
    done <<EOF
$REPLACED
EOF
}

bundle() {
    brewfile=$1
    name=${brewfile#"$DOTFILES_ROOT"/}
    if brew bundle check --file="$brewfile" >/dev/null 2>&1; then
        ok "$name"
    elif is_check; then
        differs "$name has packages that are not installed or outdated:"
        # --verbose lists each unmet entry as "→ Formula x needs to be installed or updated."
        # It does not say which of the two, so ask brew list.
        brew bundle check --verbose --file="$brewfile" 2>&1 |
            sed -En 's/^→ (Formula|Cask) ([^ ]+) .*/\1 \2/p; s/^→ (.*)/other \1/p' |
            while read -r kind package; do
                case $kind in
                    Formula) flag=--formula ;;
                    Cask) flag=--cask ;;
                    *) printf '      %s\n' "$package"; continue ;;
                esac
                if brew list "$flag" "$package" >/dev/null 2>&1; then
                    printf '      %s (outdated)\n' "$package"
                else
                    printf '      %s (not installed)\n' "$package"
                fi
            done
    else
        brew bundle --file="$brewfile"
        done_ "$name"
    fi
}

# Packages installed by hand with brew install are not in any Brewfile. List
# them so they can be added to one later; nothing is uninstalled.
report_unlisted() {
    listed=$(mktemp)
    installed=$(mktemp)
    awk -F'"' '/^[[:space:]]*(brew|cask)[[:space:]]+"/ { name = $2; sub(/.*\//, "", name); print name }' \
        "$DOTFILES_ROOT/brew/Brewfile" "$DOTFILES_ROOT"/options/*.Brewfile | sort -u >"$listed"
    { brew leaves --installed-on-request; brew list --cask -1; } 2>/dev/null | sed 's|.*/||' | sort -u >"$installed"
    unlisted=$(comm -23 "$installed" "$listed" | tr '\n' ' ')
    rm -f "$listed" "$installed"
    [ -z "$unlisted" ] || note "installed but not in any Brewfile: $unlisted"
}

check_replaced
bundle "$DOTFILES_ROOT/brew/Brewfile"
for id in $(selected_options); do
    brewfile="$DOTFILES_ROOT/options/$id.Brewfile"
    [ -f "$brewfile" ] && bundle "$brewfile"
done
if is_check; then report_unlisted; fi

finish
