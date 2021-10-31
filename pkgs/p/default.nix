{ pkgs ? import <nixpkgs> { } }:
pkgs.writeShellScriptBin "p" ''
  usage() {
    echo "usage: p <dir>"
    echo
    echo "The default projects directory is \$HOME/Projects. This can be"
    echo "overridden by setting the \$PROJ_DIR environment variable."
  }
  DIR=''${PROJ_DIR:-''${HOME}/Projects}
  SEARCH=$1
  if [ -z "''${SEARCH}" ]; then
    usage
    exit 1
  fi
  if [ ! -d $DIR ]; then
    echo "Cannot find project directory"
    exit 2
  fi
  DIRS=($(${pkgs.fd}/bin/fd -t d -H ^.git$ $DIR | xargs dirname | tr " " "\n"))
  IDX=$(echo "''${DIRS[@]}" | xargs basename -a | grep -n ".*''${SEARCH}.*" | cut -d ":" -f 1 | head -n 1)
  if [ -z "$IDX" ]; then
    echo "Cannot find project with search term ''${SEARCH}"
    exit 3
  fi
  PROJ=''${DIRS[$IDX - 1]}
  TMUX_SESSION_NAME=$(basename $PROJ)
  ${pkgs.tmux}/bin/tmux new-session -d -c $PROJ -s $TMUX_SESSION_NAME
  if [ -n "$TMUX" ]; then
    ${pkgs.tmux}/bin/tmux switch-client -t $TMUX_SESSION_NAME
  else
    ${pkgs.tmux}/bin/tmux attach-session -t $TMUX_SESSION_NAME
  fi
''
