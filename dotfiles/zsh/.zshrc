bindkey -e
bindkey \^U backward-kill-line
eval "$(direnv hook zsh)"
prompt off
PS1="%~ %% "

autoload -Uz bashcompinit && bashcompinit

complete -C "'$(which aws_completer)'" aws
