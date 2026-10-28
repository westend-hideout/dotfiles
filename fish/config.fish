# Homebrew is optional and has different prefixes on Apple Silicon and Intel.
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -x /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
end

# mise manages Ruby, Node, Python and other runtimes; keep fish usable without it.
if command -q mise
    mise activate fish | source
end

# Neovim is the only editor set up by this repository; vi and vim open it too.
if command -q nvim
    alias v nvim
    alias vi nvim
    alias vim nvim
end

# Colors and prompt are fish's bundled ones, chosen by name instead of being
# saved to universal variables or functions/fish_prompt.fish.
if status is-interactive
    fish_config theme choose "ayu Mirage"
    fish_config prompt choose nim
end

alias lsa 'ls -al'

function bind_bang
    switch (commandline -t)[-1]
        case "!"
            commandline -t $history[1]; commandline -f repaint
        case "*"
            commandline -i !
    end
end

function bind_dollar
    switch (commandline -t)[-1]
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

function fish_user_key_bindings
    bind ! bind_bang
    bind '$' bind_dollar
end

# Machine-specific settings belong here and should not be committed.
if test -f ~/.config/fish/local.fish
    source ~/.config/fish/local.fish
end
