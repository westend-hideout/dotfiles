# ~/.config/fish/conf.d/ghostty-theme.fish

function _ghostty_osc
    if test -n "$TMUX"
        # tmux DCS passthrough: ESC文字をすべて二重化
        set -l escaped (string replace -a \e \e\e -- $argv[1])
        printf '\ePtmux;%s\e\\' "$escaped"
    else
        printf '%s' "$argv[1]"
    end
end

function _ghostty_theme_apply --on-variable PWD
    set -l git_root (command git rev-parse --show-toplevel 2>/dev/null)

    if test -n "$git_root" -a -f "$git_root/.ghostty-theme"
        set -l title ""
        set -l bg ""
        set -l fg ""

        while read -l line
            string match -qr '^\s*#|^\s*$' -- $line; and continue
            set -l key (string replace -r '=.*' '' -- $line)
            set -l value (string replace -r '^[^=]*=' '' -- $line)
            switch $key
                case title
                    set title $value
                case bg
                    set bg $value
                case fg
                    set fg $value
            end
        end < "$git_root/.ghostty-theme"

        test -n "$title"; and _ghostty_osc (printf '\e]0;%s\a' "$title")
        test -n "$bg"; and _ghostty_osc (printf '\e]11;%s\e\\' "$bg")
        test -n "$fg"; and _ghostty_osc (printf '\e]10;%s\e\\' "$fg")
    else
        # workspace外: デフォルトに戻す
        _ghostty_osc (printf '\e]0;%s\a' (basename $PWD))
        _ghostty_osc (printf '\e]111\e\\')
        _ghostty_osc (printf '\e]110\e\\')
    end
end

# シェル起動時にも適用(fish -c やスクリプトの出力に制御文字が混ざらないよう、対話シェルだけ)
if status is-interactive
    _ghostty_theme_apply
end
