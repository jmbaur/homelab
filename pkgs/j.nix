{ writeShellApplication
, fzf
, tmux
}:
writeShellApplication {
  name = "j";
  runtimeInputs = [ fzf tmux ];
  text = ''
    function usage() {
      cat <<EOF
    Usage: j <dir>

    The default projects directory is \$HOME/Projects. This can be
    overridden by setting the \$PROJ_DIR environment variable.
    EOF
    }

    directory=''${PROJ_DIR:-''${HOME}/Projects}
    if ! test -d "$directory"; then
      echo "Cannot find projects directory"
      usage
      exit 1
    fi

    tmux_session_path=$(find "$directory" -name .git -type d -prune | sed "s,/\.git,," | { grep ".*''${1:-}.*" || true; } | fzf -1)
    tmux_session_name=$(echo -n "$tmux_session_path" | sed "s,$directory/,," | sed "s,\.,_,g")

    if ! tmux list-sessions -F "#{session_name}" 2>/dev/null | grep --quiet "$tmux_session_name"; then
      tmux new-session -d -s "$tmux_session_name" -c "$tmux_session_path"
    fi

    if test -n "''${TMUX:-}"; then
      tmux switch-client -t "$tmux_session_name"
    else
      tmux attach-session -t "$tmux_session_name"
    fi
  '';
}
