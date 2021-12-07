{ writeShellApplication, fd, tmux, fzf }:
writeShellApplication {
  name = "p";
  runtimeInputs = [ fzf fd tmux ];
  text = ''
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
    if [ ! -d "$DIR" ]; then
            echo "Cannot find project directory"
            exit 2
    fi
    MATCH=$(fd --type=directory --max-depth=4 --hidden "^.git$" "$DIR" | sed "s/\/\.git//" | grep ".*''${SEARCH}.*" | fzf -0 -1)
    if [ -z "''${MATCH}" ]; then
            echo "Cannot find project with search term ''${SEARCH}"
            exit 3
    fi
    PROJECT_NAME=$(basename "$MATCH")
    TMUX_SESSION_NAME=''${PROJECT_NAME:0:7}
    tmux new-session -d -c "''${MATCH}" -s "$TMUX_SESSION_NAME"
    if [ -n "$TMUX" ]; then
            tmux switch-client -t "$TMUX_SESSION_NAME"
    else
            tmux attach-session -t "$TMUX_SESSION_NAME"
    fi
  '';
}
