#!/bin/sh
# Copy config files from this repository into $HOME.
#
# Each copied file starts with a marker line that records where it came from
# and the sha256 of the repository content at copy time, for example:
#   # westend-hideout/dotfiles: fish/config.fish [copied 2026-10-28 sha256:3f2a9c1e0b4d]
# With it a rerun can tell whether the file was edited here and whether the
# repository changed since, so it only asks when both happened or when the
# file did not come from this repository. Machine-specific settings belong in
# ~/.config/fish/local.fish, which is never copied.
#
# Before a file is overwritten after asking, it is moved to
# ~/.dotfiles-backup/<timestamp>/ keeping its path under $HOME.
# Without a terminal nothing is overwritten.
set -eu
# shellcheck source=../lib/common.sh
. "$(dirname -- "$0")/../lib/common.sh"

BACKUP_ROOT="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
MISE_CONF_D="$HOME/.config/mise/conf.d"
ORIGIN=$(git -C "$DOTFILES_ROOT" remote get-url origin 2>/dev/null |
    sed -E 's#\.git$##; s#^.*[:/]([^/]+/[^/]+)$#\1#') || true
ORIGIN=${ORIGIN:-dotfiles}

short_hash() { shasum -a 256 | cut -c 1-12; }

comment_prefix() {
    case $1 in *.vim) printf '"' ;; *) printf '#' ;; esac
}

# Print the hash in the marker line of $1 if it was copied from repository path $2.
recorded_hash() {
    head -n 1 "$1" | sed -n "s|^.* $ORIGIN: $2 \[copied [0-9-]* sha256:\([0-9a-f]*\)\]\$|\1|p"
}

# Write repository path $1 to $2 with a marker line. Writing to a temporary
# file and renaming replaces a symlink instead of writing through it.
write_copy() {
    mkdir -p "$(dirname "$2")"
    tmp="$2.dotfiles-tmp.$$"
    {
        printf '%s %s: %s [copied %s sha256:%s]\n' "$(comment_prefix "$2")" "$ORIGIN" "$1" \
            "$(date +%Y-%m-%d)" "$(short_hash <"$DOTFILES_ROOT/$1")"
        cat "$DOTFILES_ROOT/$1"
    } >"$tmp"
    mv -f "$tmp" "$2"
}

backup() {
    backup_path="$BACKUP_ROOT/${1#"$HOME"/}"
    mkdir -p "$(dirname "$backup_path")"
    mv "$1" "$backup_path"
    done_ "backed up $1 -> $backup_path"
}

# Show how $2 differs from repository path $1. $3 is 1 when $2 has a marker line.
show_diff() {
    if [ -L "$2" ] && [ ! -e "$2" ]; then
        printf '  %s is a broken link to %s\n' "$2" "$(readlink "$2")"
    elif [ -d "$2" ]; then
        printf '  %s is a directory\n' "$2"
    else
        if [ "$3" = 1 ]; then tail -n +2 "$2"; else cat "$2"; fi |
            diff -u -L "$2 (current)" -L "$1 (repository)" - "$DOTFILES_ROOT/$1" |
            awk -v max=60 '
                NR <= max { print "    " $0 }
                END { if (NR > max) printf "    ... %d more lines\n", NR - max }'
    fi
}

# Copy repository path $1 to $2.
copy_file() {
    rel=$1
    target=$2
    repo_hash=$(short_hash <"$DOTFILES_ROOT/$rel")

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        if is_check; then differs "$target does not exist"; return; fi
        write_copy "$rel" "$target"
        done_ "copied $rel -> $target"
        return
    fi

    recorded=""
    if [ -f "$target" ]; then recorded=$(recorded_hash "$target" "$rel"); fi

    if [ -n "$recorded" ]; then
        local_hash=$(tail -n +2 "$target" | short_hash)
        if [ "$local_hash" = "$repo_hash" ]; then
            ok "$target"
            return
        fi
        if [ "$local_hash" = "$recorded" ]; then
            # Not edited here, so there is nothing to lose by updating.
            if is_check; then differs "$target: the repository changed (updated without asking)"; return; fi
            write_copy "$rel" "$target"
            done_ "updated $target"
            return
        fi
        if [ "$repo_hash" = "$recorded" ]; then
            note "$target was edited here; kept (the repository has not changed)"
            return
        fi
        reason="was edited here and the repository also changed"
        has_marker=1
    else
        if [ -f "$target" ] && cmp -s "$target" "$DOTFILES_ROOT/$rel"; then
            if is_check; then differs "$target: same content, marker will be added"; return; fi
            write_copy "$rel" "$target"
            done_ "added marker to $target"
            return
        fi
        reason="did not come from $ORIGIN"
        has_marker=0
    fi

    if is_check; then differs "$target $reason (you will be asked)"; return; fi
    printf '  %s %s:\n' "$target" "$reason"
    show_diff "$rel" "$target" "$has_marker"
    if ! choose_replace "  Overwrite $target?" "Skip (keep current file)" "Back up and overwrite"; then
        warn "kept $target"
        return
    fi
    backup "$target"
    write_copy "$rel" "$target"
    done_ "copied $rel -> $target"
}

copy_file fish/config.fish "$HOME/.config/fish/config.fish"
copy_file fish/conf.d/ghostty-theme.fish "$HOME/.config/fish/conf.d/ghostty-theme.fish"
copy_file nvim/init.vim "$HOME/.config/nvim/init.vim"
copy_file colors/one.vim "$HOME/.config/nvim/colors/one.vim"
copy_file ghostty/config "$HOME/.config/ghostty/config"
copy_file mise/config.toml "$HOME/.config/mise/config.toml"
copy_file uv/uv.toml "$HOME/.config/uv/uv.toml"

# Tool versions of the chosen languages.
for id in $(selected_options); do
    [ -f "$DOTFILES_ROOT/options/$id.mise.toml" ] && copy_file "options/$id.mise.toml" "$MISE_CONF_D/$id.toml"
done

# Remove the versions of languages that are no longer chosen, but only files
# copied from here and not edited since. Anything else in conf.d is left alone.
if [ -d "$MISE_CONF_D" ]; then
    for target in "$MISE_CONF_D"/*.toml; do
        [ -f "$target" ] || continue
        id=$(basename "$target" .toml)
        is_selected "$id" && continue
        recorded=$(recorded_hash "$target" "options/$id.mise.toml")
        [ -n "$recorded" ] || continue
        if [ "$(tail -n +2 "$target" | short_hash)" != "$recorded" ]; then
            note "$target is no longer chosen but was edited here; kept"
        elif is_check; then
            differs "$target is no longer chosen (will be removed)"
        else
            rm "$target"
            done_ "removed $target"
        fi
    done
fi

finish
