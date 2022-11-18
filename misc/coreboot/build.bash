# shellcheck shell=bash

set -o errexit
set -o nounset
set -o pipefail

if [[ -d /config ]]; then
	rsync -aP /config/ /build/
fi

make CPUS="$(nproc)"

cp build/coreboot.rom /out/coreboot.rom
