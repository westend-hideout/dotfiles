#!/bin/sh
# Install the language versions in ~/.config/mise/conf.d/ (copied by the files step).
# Projects can still pin their own versions with .ruby-version, mise.toml, etc.
set -eu
# shellcheck source=../lib/common.sh
. "$(dirname -- "$0")/../lib/common.sh"

command -v mise >/dev/null 2>&1 || {
    is_check && { differs "mise is not installed"; finish; }
    die "mise is not installed (run the packages step first)"
}

# Run from $HOME so a project's mise.toml in the current directory is not used.
cd "$HOME"
missing=$(mise ls --current --missing --no-header)
if [ -z "$missing" ]; then
    ok "all global tool versions are installed"
elif is_check; then
    differs "not installed: $(printf '%s\n' "$missing" | awk '{ print $1 "@" $2 }' | tr '\n' ' ')"
else
    mise install
    done_ "installed global tool versions"
fi

finish
