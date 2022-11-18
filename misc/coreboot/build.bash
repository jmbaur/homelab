# shellcheck shell=bash

set -o errexit
set -o nounset
set -o pipefail

if [[ -d /config ]]; then
	rsync -aP /config/ /build/
fi

make -C payloads/external/depthcharge olddefconfig
make -C payloads/external/depthcharge

make olddefconfig
make

cp build/coreboot.rom /out/coreboot.rom
