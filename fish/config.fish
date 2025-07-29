if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Disable greeting
set fish_greeting

# Shell aliases
alias c="clear"
alias e="exit"
alias vim="nvim"
alias ls="eza"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias notes="cd ~/Documents/obsidian/"
alias courses="cd ~/Documents/askerra/content/courses/"
alias projects="cd ~/Documents/askerra/content/projects/"
alias students="cd ~/Documents/askerra/private-students/"
alias assets="cd ~/Documents/askerra/content/assets/"

# Custom key bindings
function fish_user_key_bindings
    fish_default_key_bindings
    bind \cn history-search-forward
    bind \cp history-search-backward
end

starship init fish | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
