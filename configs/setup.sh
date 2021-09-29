#!/usr/bin/env bash

set -e

pushd "$(dirname "$0")" >/dev/null

stow_with_flags() {
	stow --no-folding --dir="${PWD}" --target="${HOME}" "$@"
}

stow_with_flags alacritty
stow_with_flags git
stow_with_flags gtk
stow_with_flags i3
stow_with_flags tmux
stow_with_flags vim
stow_with_flags zsh

popd >/dev/null
