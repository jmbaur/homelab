{ writeShellApplication, fd, tmux, fzf }:
writeShellApplication {
  name = "p";
  runtimeInputs = [ fzf fd tmux ];
  text = ''
    usage() {
            cat <<EOF
    Usage: p <dir>

    The default projects directory is \$HOME/Projects. This can be
    overridden by setting the \$PROJ_DIR environment variable.
    EOF
    }

    directory=''${PROJ_DIR:-''${HOME}/Projects}
    search=''${1:-}
    if test -z "$search"; then
            usage
            exit 1
    fi
    if ! test -d "$directory"; then
            echo "Cannot find projects directory"
            usage
            exit 2
    fi
    tmux_session_path=$(fd --type=directory --max-depth=4 --hidden "^.git$" "$directory" | sed "s,/\.git,," | { grep ".*''${search}.*" || true; } | fzf -1)
    if test -z "$tmux_session_path"; then
            echo "Cannot find project with search term $search"
            exit 3
    fi

    tmux_session_name=$(echo -n "$tmux_session_path" | sed "s,$directory/,," | sed "s,\.,_,g")

    if ! tmux list-sessions -F "#{session_name}" | grep --quiet "$tmux_session_name"; then
            tmux new-session -d -s "$tmux_session_name" -c "$tmux_session_path"
    fi

    if test -n "''${TMUX:-}"; then
            tmux switch-client -t "$tmux_session_name"
    else
            tmux attach-session -t "$tmux_session_name"
    fi
  '';
}
