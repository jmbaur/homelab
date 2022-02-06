{ writeShellApplication
, fd
, tmux
, zf
}:
writeShellApplication {
  name = "p";
  runtimeInputs = [ fd tmux zf ];
  text = ''
    function usage() {
      cat <<EOF
    Usage: p <dir>

    The default projects directory is \$HOME/Projects. This can be
    overridden by setting the \$PROJ_DIR environment variable.
    EOF
    }

    directory=''${PROJ_DIR:-''${HOME}/Projects}
    if ! test -d "$directory"; then
      echo "Cannot find projects directory"
      usage
      exit 2
    fi

    # TODO(jared): don't hardcode depth
    tmux_session_path=$(fd --type=directory --max-depth=4 --hidden "^.git$" "$directory" | sed "s,/\.git,," | zf)

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
