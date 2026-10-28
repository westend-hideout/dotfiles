#!/bin/sh
# Install Homebrew. Its installer also installs the Xcode Command Line Tools (and git).
set -eu
# shellcheck source=../lib/common.sh
. "$(dirname -- "$0")/../lib/common.sh"

if command -v brew >/dev/null 2>&1; then
    ok "Homebrew $(brew --version | head -n 1 | cut -d ' ' -f 2)"
elif is_check; then
    differs "Homebrew is not installed"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    done_ "installed Homebrew"
fi

finish
