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
    sed -n '2,10s/^# \{0,1\}//p' "$0"
    printf '\nsteps: %s\n' "$ALL_STEPS"
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
        printf '==> %s\n' "$step"
        status=0
        DOTFILES_MODE=$run_mode DOTFILES_RECONFIGURE=$reconfigure sh "$ROOT/steps/$step.sh" || status=$?
        if [ "$status" -eq 3 ] && [ "$run_mode" = check ]; then
            run_drift=1
        elif [ "$status" -ne 0 ]; then
            # Later steps depend on earlier ones, so stop here. Rerunning resumes safely.
            printf '\nFailed at step "%s". Fix the error above and run install.sh again.\n' "$step" >&2
            exit "$status"
        fi
    done
    [ "$run_drift" -eq 0 ] || return 3
}

if [ "$mode" = check ]; then
    status=0
    run_steps check || status=$?
    if [ "$status" -eq 3 ]; then
        printf '\nThis Mac differs from the repository. Run ./install.sh to apply.\n'
        exit 1
    fi
    printf '\nThis Mac matches the repository.\n'
    exit 0
fi

if [ "$yes" -ne 1 ]; then
    printf 'Checking what will change. Nothing is changed yet.\n\n'
    status=0
    run_steps check || status=$?
    if [ "$status" -eq 0 ]; then
        printf '\nThis Mac already matches the repository. Nothing to do.\n'
        exit 0
    fi
    printf '\nThe steps above marked "differs" will be applied.\n'
    printf 'Packages of options chosen in the select step are installed too.\n\n'
    confirm "Apply these changes?" || { printf 'Cancelled. Nothing was changed.\n'; exit 1; }
    printf '\n'
fi

run_steps apply
printf '\nDone. Open a new terminal to load the settings.\n'
