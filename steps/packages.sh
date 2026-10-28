#!/bin/sh
# Install the base Brewfile and the Brewfiles of the chosen options.
# brew bundle installs what is missing and upgrades what is outdated. Apps in
# /Applications installed outside Homebrew are moved to the Trash after asking.
# Deselected options are never uninstalled.
set -eu
# shellcheck source=../lib/common.sh
. "$(dirname -- "$0")/../lib/common.sh"

command -v brew >/dev/null 2>&1 || {
    is_check && { differs "Homebrew is not installed"; finish; }
    die "Homebrew is not installed (install it from https://brew.sh/ja/)"
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

BACKUP_ROOT="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Print the names cask $1 installs its apps under in /Applications, one per
# line: the target when the cask renames the app, else the app's file name.
cask_apps() {
    brew info --cask --json=v2 "$1" 2>/dev/null | jq -r '
        .casks[0].artifacts[] | select(type == "object" and has("app")) | .app
        | (map(objects | .target) | first) as $target
        | if $target then $target else (map(strings) | first | split("/") | last) end'
}

# Only a plain "Name.app" may be touched, so an empty or odd name from the cask
# definition can never resolve to /Applications itself or a path elsewhere.
is_plain_app_name() {
    case $1 in
        '' | */* | *..* | .app) return 1 ;;
        *.app) return 0 ;;
        *) return 1 ;;
    esac
}

# Move an app to the Trash (macOS 15+), or to the backup directory without it.
# Returns 1 if the app could not be moved. trash exits 0 on failure unless -s
# is given, so the app's absence is checked as well.
discard_app() {
    if [ -x /usr/bin/trash ]; then
        /usr/bin/trash -s "$1" && [ ! -e "$1" ] || return 1
        done_ "moved $1 to the Trash"
    else
        backup_path="$BACKUP_ROOT/Applications/$(basename "$1")"
        mkdir -p "$(dirname "$backup_path")"
        mv "$1" "$backup_path" || return 1
        done_ "moved $1 -> $backup_path"
    fi
}

# Apps from the App Store carry a receipt; the App Store keeps them updated.
is_app_store_app() {
    [ -e "$1/Contents/_MASReceipt/receipt" ]
}

# An app in /Applications that Homebrew did not install makes brew bundle fail
# unless it is exactly the version being installed. Offer to move it to the
# Trash so brew can install its own copy (brew --force would delete it for good).
# Apps from the App Store are left to the App Store. Returns 1 when the app is
# kept for any reason, so the Brewfile is skipped.
prepare_casks() {
    # Cask names never contain spaces, so splitting on words is fine.
    casks=$(awk -F'"' '/^[[:space:]]*cask[[:space:]]+"/ { print $2 }' "$1")
    for cask in $casks; do
        brew list --cask "$cask" >/dev/null 2>&1 && continue
        apps=$(cask_apps "$cask")
        [ -n "$apps" ] || continue
        # A here-document keeps the loop in this shell so differs and return take effect.
        # It is read from fd 3 so stdin stays the terminal for choose_replace.
        while IFS= read -r app <&3; do
            if ! is_plain_app_name "$app"; then
                warn "$cask installs an app as '$app'; not checked for a copy installed by hand"
                continue
            fi
            app_path="/Applications/$app"
            [ -e "$app_path" ] || continue
            if is_app_store_app "$app_path"; then
                note "$app_path is from the App Store; skipped $cask (update it in the App Store)"
                return 1
            fi
            current=$(defaults read "$app_path/Contents/Info" CFBundleShortVersionString 2>/dev/null) || current=unknown
            latest=$(brew info --cask --json=v2 "$cask" | jq -r '.casks[0].version | split(",")[0]')
            message="$app_path was installed outside Homebrew ($current, Homebrew has $latest)"
            if is_check; then
                differs "$message (you will be asked)"
                continue
            fi
            printf '  %s は Homebrew 以外で入れたアプリです(今: %s、Homebrew: %s)。\n' "$app_path" "$current" "$latest"
            if ! choose_replace "  $app を Homebrew の版で入れ直しますか?" \
                "スキップ(今のアプリを残す)" "ゴミ箱に移して Homebrew で入れ直す"; then
                warn "kept $app_path; skipped $cask"
                return 1
            fi
            if ! discard_app "$app_path"; then
                warn "could not move $app_path (check its owner and permissions); skipped $cask"
                return 1
            fi
        done 3<<EOF
$apps
EOF
    done
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
    [ -f "$brewfile" ] || continue
    prepare_casks "$brewfile" || continue
    bundle "$brewfile"
done
if is_check; then report_unlisted; fi

finish
