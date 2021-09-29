bindkey -e
bindkey \^U backward-kill-line
eval "$(direnv hook zsh)"
prompt off
PS1="%~ %% "
