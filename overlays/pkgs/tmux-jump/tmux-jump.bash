# shellcheck shell=bash

default_base_directory=${XDG_STATE_HOME:-${HOME}/.local/state}/projects

function usage() {
	if [[ -n ${1-} ]]; then
		echo "$1"
		echo
	fi
	echo "Usage: $(basename "$0") [PROJECT NAME]"
	echo
	echo "The default projects directory is $default_base_directory. This can be"
	echo "overridden by setting the $PROJECTS_DIR environment variable."
}

base_directory=${PROJECTS_DIR:-$default_base_directory}

if ! test -d "$base_directory"; then
	usage "Cannot find projects directory"
	exit 1
fi

tmux_session_path=
if ! tmux_session_path=$(
	fd '^\.git$' \
		--base-directory "$base_directory" \
		--hidden \
		--max-depth 2 \
		--no-ignore |
		sed 's,/\.git/\?,,' |
		{ [[ -n ${1-} ]] && grep ".*$1.*" || cat; } |
		fzy
); then
	echo "No matches"
	exit 2
fi

# Decimals are not allowed in tmux's statusline.
function escape_basename() {
	basename "$1" | sed "s,\.,_,g"
}

tmux_session_name="$(escape_basename "$tmux_session_path")"

in_tmux() {
	test "${TERM_PROGRAM:-}" == "tmux"
}

# Output will be empty if session with the name we want doesn't exist,
# otherwise it will be an integer representing the number of connected clients.
clients_attached=$(tmux list-sessions \
	-f "#{==:#{session_name},$tmux_session_name}" \
	-F "#{session_attached}" 2>/dev/null || echo)
if [[ -z $clients_attached ]]; then
	tmux new-session -d \
		-s "$tmux_session_name" \
		-c "${base_directory}/${tmux_session_path}"
fi

if in_tmux; then
	# Currently attached to a tmux session, switch to our new one.
	exec tmux switch-client -t "$tmux_session_name"
else
	exec tmux attach-session -t "$tmux_session_name"
fi
