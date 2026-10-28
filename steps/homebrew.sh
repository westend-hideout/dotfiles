#!/bin/sh
# Check that Homebrew is installed. Installing it is left to the official
# instructions at https://brew.sh/, so this step never runs an installer.
set -eu
# shellcheck source=../lib/common.sh
. "$(dirname -- "$0")/../lib/common.sh"

if command -v brew >/dev/null 2>&1; then
    ok "Homebrew $(brew --version | head -n 1 | cut -d ' ' -f 2)"
elif is_check; then
    differs "Homebrew is not installed (install it from https://brew.sh/ja/)"
else
    die "Homebrew is not installed. Install it with the command on https://brew.sh/ja/ and run install.sh again."
fi

finish
