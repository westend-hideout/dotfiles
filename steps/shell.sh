#!/bin/sh
# Make Homebrew's fish the login shell. Needs the user's password (sudo / chsh).
set -eu
# shellcheck source=../lib/common.sh
. "$(dirname -- "$0")/../lib/common.sh"

command -v brew >/dev/null 2>&1 || {
    is_check && { differs "Homebrew is not installed"; finish; }
    die "Homebrew is not installed (run the homebrew step first)"
}
fish_path="$(brew --prefix)/bin/fish"
[ -x "$fish_path" ] || {
    is_check && { differs "$fish_path is not installed"; finish; }
    die "$fish_path is not installed (run the packages step first)"
}

if grep -qx "$fish_path" /etc/shells; then
    ok "$fish_path is in /etc/shells"
elif is_check; then
    differs "$fish_path is not in /etc/shells"
else
    printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
    done_ "added $fish_path to /etc/shells"
fi

login_shell=$(dscl . -read "/Users/$(id -un)" UserShell | awk '{ print $2 }')
if [ "$login_shell" = "$fish_path" ]; then
    ok "login shell is $fish_path"
elif is_check; then
    differs "login shell is $login_shell, not $fish_path"
else
    chsh -s "$fish_path"
    done_ "changed login shell to $fish_path (takes effect in new terminals)"
fi

finish
