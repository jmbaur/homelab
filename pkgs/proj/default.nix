self: super:
{
  proj = super.writeShellScriptBin "proj" ''
    DIR=''${PROJ_DIR:-$HOME/Projects}
    if [ ! -d $DIR ]; then
      echo "Cannot find project directory"
      exit 1
    fi
    PROJ=$(${super.fd}/bin/fd -t d -H ^.git$ $DIR | xargs dirname | ${super.fzf}/bin/fzf)
    if [ -z "$PROJ" ]; then
      exit 1
    fi
    TMUX_SESSION_NAME=$(basename $PROJ)
    ${super.tmux}/bin/tmux new-session -d -c $PROJ -s $TMUX_SESSION_NAME
    if [ -n "$TMUX" ]; then
      ${super.tmux}/bin/tmux switch-client -t $TMUX_SESSION_NAME
    else
      ${super.tmux}/bin/tmux attach-session -t $TMUX_SESSION_NAME
    fi
  '';
}
