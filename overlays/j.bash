# shellcheck shell=bash

function usage() {
	if [[ -n ${1:-} ]]; then
		echo "$1"
		echo
	fi
	echo "Usage: $(basename "$0") [PROJECT NAME]"
	echo
	echo "The default projects directory is $HOME/Projects. This can be"
	echo "overridden by setting the $PROJ_DIR environment variable."
}

directory=${PROJ_DIR:-${HOME}/Projects}
if ! test -d "$directory"; then
	usage "Cannot find projects directory"
	exit 1
fi

tmux_session_path=
if ! tmux_session_path=$(
	fd "^\.git$" "$directory" \
		--hidden \
		--type directory \
		--max-depth 5 \
		--no-ignore |
		sed "s,/\.git/,," |
		{ [[ -n ${1:-} ]] && grep ".*$1.*" || cat; } |
		sk -01
); then
	echo "No matches"
	exit 2
fi

tmux_session_name=$(
	echo -n "$tmux_session_path" |
		sed "s,$directory/,," |
		sed "s,\.,_,g"
)

clients_attached=$(tmux start \; list-sessions -f "#{==:#{session_name},$tmux_session_name}" -F "#{session_attached}" 2>/dev/null)
if [[ -z $clients_attached ]]; then
	tmux new-session -d -s "$tmux_session_name" -c "$tmux_session_path"
elif [[ $clients_attached -gt 0 ]]; then
	exit 0
fi

if [[ -n ${TMUX:-} ]]; then
	# current attached to a tmux session
	tmux switch-client -t "$tmux_session_name"
else
	tmux attach-session -t "$tmux_session_name"
fi
