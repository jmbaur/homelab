#!/usr/bin/env bash

set -e

pushd "$(dirname "$0")" >/dev/null

HOST="${1:-$HOSTNAME}"

stow_with_flags() {
	echo Stowing "$@"
	stow --restow --no-folding --dir="${PWD}" --target="${HOME}" "$@"
}

stow_with_flags alacritty
stow_with_flags git
stow_with_flags gtk
stow_with_flags i3
stow_with_flags psql
stow_with_flags ssh
stow_with_flags tmux
stow_with_flags vim
stow_with_flags xorg
stow_with_flags zsh

# Host specific configs
if [[ -d "${HOST}" ]]; then
	stow_with_flags "${HOST}"
fi

popd >/dev/null
