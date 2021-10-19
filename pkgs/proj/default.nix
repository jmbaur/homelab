{ pkgs ? import <nixpkgs> { } }:
pkgs.writeShellScriptBin "proj" ''
  DIR=''${PROJ_DIR:-$HOME/Projects}
  if [ ! -d $DIR ]; then
    echo "Cannot find project directory"
    exit 1
  fi
  PROJ=$(${pkgs.fd}/bin/fd -t d -H ^.git$ $DIR | xargs dirname | ${pkgs.fzf}/bin/fzf)
  if [ -z "$PROJ" ]; then
    exit 1
  fi
  TMUX_SESSION_NAME=$(basename $PROJ)
  ${pkgs.tmux}/bin/tmux new-session -d -c $PROJ -s $TMUX_SESSION_NAME
  if [ -n "$TMUX" ]; then
    ${pkgs.tmux}/bin/tmux switch-client -t $TMUX_SESSION_NAME
  else
    ${pkgs.tmux}/bin/tmux attach-session -t $TMUX_SESSION_NAME
  fi
''
