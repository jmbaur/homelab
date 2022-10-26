build:
	#!/usr/bin/env bash
	nix build -L \
		.\#ipwatch \
		.\#linux_cn913x \
		.\#runner-nix \
		.\#webauthn-tiny
