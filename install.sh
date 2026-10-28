#!/bin/sh
# Set up this Mac from the repository. Safe to run any number of times:
# every step skips what is already in place.
#
#   ./install.sh                 show what will change, ask, then apply all steps
#   ./install.sh mise files      the same for the given steps only
#   ./install.sh --check         show what differs without changing anything
#   ./install.sh --reconfigure   choose optional tools and apps again
#   ./install.sh --yes           apply without asking first (existing config
#                                files are still never replaced without asking)
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
DOTFILES_ROOT=$ROOT
# shellcheck source=lib/common.sh
. "$ROOT/lib/common.sh"
ALL_STEPS="homebrew select packages files mise shell editor"

usage() {
    cat <<EOF
この Mac をリポジトリの状態に揃えます。何度実行しても、揃っているものはスキップします。

  ./install.sh                 差分を表示し、確認してから全部の手順を適用する
  ./install.sh mise files      指定した手順だけ、同じように適用する
  ./install.sh --check         差分を表示するだけ。何も変更しない
  ./install.sh --reconfigure   入れるツールやアプリを選び直す
  ./install.sh --yes           最初の確認を飛ばす(設定ファイルの上書きなどは飛ばさずに聞く)

手順: $ALL_STEPS
EOF
}

mode=apply
reconfigure=0
yes=0
steps=""
for arg in "$@"; do
    case $arg in
        --check) mode=check ;;
        --reconfigure) reconfigure=1 ;;
        --yes) yes=1 ;;
        -h | --help) usage; exit 0 ;;
        -*) usage >&2; exit 2 ;;
        *)
            [ -f "$ROOT/steps/$arg.sh" ] || { printf 'unknown step: %s\n\n' "$arg" >&2; usage >&2; exit 2; }
            steps="$steps $arg"
            ;;
    esac
done
steps=${steps:-$ALL_STEPS}

# Run the steps in the given mode. In check mode, returns 3 if anything differs.
run_steps() {
    run_mode=$1
    run_drift=0
    for step in $steps; do
        printf '%s==> %s%s\n' "$BOLD" "$step" "$RESET"
        status=0
        DOTFILES_MODE=$run_mode DOTFILES_RECONFIGURE=$reconfigure sh "$ROOT/steps/$step.sh" || status=$?
        if [ "$status" -eq 3 ] && [ "$run_mode" = check ]; then
            run_drift=1
        elif [ "$status" -ne 0 ]; then
            # Later steps depend on earlier ones, so stop here. Rerunning resumes safely.
            printf '\n%sFailed at step "%s".%s Fix the error above and run install.sh again.\n' \
                "$ERR_RED" "$step" "$ERR_RESET" >&2
            exit "$status"
        fi
    done
    [ "$run_drift" -eq 0 ] || return 3
}

if [ "$mode" = check ]; then
    status=0
    run_steps check || status=$?
    if [ "$status" -eq 3 ]; then
        printf '\n%sリポジトリと違うところがあります。%s ./install.sh で適用できます。\n' "$CYAN" "$RESET"
        exit 1
    fi
    printf '\n%sリポジトリの状態と揃っています。%s\n' "$GREEN" "$RESET"
    exit 0
fi

if [ "$yes" -ne 1 ]; then
    printf '変更される内容を確認します。まだ何も変更しません。\n\n'
    status=0
    run_steps check || status=$?
    if [ "$status" -eq 0 ]; then
        printf '\n%sリポジトリの状態と揃っています。何もすることはありません。%s\n' "$GREEN" "$RESET"
        exit 0
    fi
    printf '\n上の「differs」の行が適用されます。\n'
    printf 'select の手順で選んだツールやアプリも、あわせて入れます。\n\n'
    confirm "適用しますか?" || { printf '中止しました。何も変更していません。\n'; exit 1; }
    printf '\n'
fi

run_steps apply
printf '\n%s完了しました。%s 新しいターミナルを開くと、設定が読み込まれます。\n' "$GREEN" "$RESET"
