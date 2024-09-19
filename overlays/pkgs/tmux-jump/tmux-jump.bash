# shellcheck shell=bash

function usage() {
	if [[ -n ${1-} ]]; then
		echo "$1"
		echo
	fi
	echo "Usage: $(basename "$0") [PROJECT NAME]"
	echo
	echo "The default projects directory is $HOME/projects. This can be"
	echo "overridden by setting the $PROJECTS_DIR environment variable."
}

base_directory=${PROJECTS_DIR:-${HOME}/projects}
if ! test -d "$base_directory"; then
	usage "Cannot find projects directory"
	exit 1
fi

cd "$base_directory" || exit

tmux_session_path=
if ! tmux_session_path=$(
	fd "^\.git$" \
		--hidden \
		--type directory \
		--max-depth 2 \
		--no-ignore |
		sed "s,/\.git/,," |
		{ [[ -n ${1-} ]] && grep ".*$1.*" || cat; } |
		sk \
			--exit-0 \
			--select-1 \
			--preview-window=down \
			--preview="git -C {} remote -v"
); then
	echo "No matches"
	exit 2
fi

# decimals are not allowed in tmux's statusline
function escape_basename() {
	basename "$1" | sed "s,\.,_,g"
}

tmux_session_name="$(escape_basename "$tmux_session_path")"

clients_attached=$(tmux list-sessions \
	-f "#{==:#{session_name},$tmux_session_name}" \
	-F "#{session_attached}" 2>/dev/null || echo)
if [[ -z $clients_attached ]]; then
	tmux new-session -d \
		-s "$tmux_session_name" \
		-c "${base_directory}/${tmux_session_path}"
elif [[ $clients_attached -gt 0 ]]; then
	exit 0
fi

if [[ -n ${TMUX-} ]]; then
	# current attached to a tmux session
	exec tmux switch-client -t "$tmux_session_name"
else
	exec tmux attach-session -t "$tmux_session_name"
fi
