# shellcheck shell=bash

if [[ -d /config ]]; then
	rsync -aP /config/ /build/
fi
make
cp build/coreboot.rom /out/coreboot.rom
