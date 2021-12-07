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
    directory=''${PROJ_DIR:-''${HOME}/Projects}
    search=''${1:-}
    if [ -z "$search" ]; then
            usage
            exit 1
    fi
    if [ ! -d "$directory" ]; then
            echo "Cannot find project directory"
            exit 2
    fi
    tmux_session_path=$(fd --type=directory --max-depth=4 --hidden "^.git$" "$directory" | sed "s,/\.git,," | { grep ".*''${search}.*" || true; } | fzf -1)
    if [ -z "$tmux_session_path" ]; then
            echo "Cannot find project with search term $search"
            exit 3
    fi

    existing_session=
    if tmux list-sessions 2>/dev/null; then
      existing_session=$(tmux list-sessions -F "#{session_path}:#{session_name}" | { grep "''${tmux_session_path}\:.*" || true; } | sed "s,''${tmux_session_path}:\(.*\),\1,")
    fi
    if [ -z "$existing_session" ]; then
            existing_session=$(tmux new-session -d -c "$tmux_session_path" -P -F "#{session_name}")
    fi
    if test -n "''${TMUX:-}"; then
            tmux switch-client -t "$existing_session"
    else
            tmux attach-session -t "$existing_session"
    fi
  '';
}
