# shellcheck shell=bash

set -o errexit
set -o nounset
set -o pipefail

export ARCH=arm64
export CP_NUM=1
export CROSS_COMPILE=aarch64-linux-gnu-
export DTB_UBOOT="cn9130-cf-pro"
export UBOOT_ENVIRONMENT="spi"

PARALLEL=$(getconf _NPROCESSORS_ONLN)

pushd build/u-boot/
git am ../../patches/u-boot/*.patch
cp configs/sr_cn913x_cex7_defconfig .config
make olddefconfig
make -j"${PARALLEL}" DEVICE_TREE=$DTB_UBOOT
popd

cp build/u-boot/u-boot.bin binaries/u-boot/u-boot.bin
export BL33=$PWD/binaries/u-boot/u-boot.bin
export SCP_BL2=$PWD/binaries/atf/mrvl_scp_bl2.img

pushd build/mv-ddr-marvell
git am ../../patches/mv-ddr-marvell/*.patch
popd

pushd build/arm-trusted-firmware
git am ../../patches/arm-trusted-firmware/*.patch
make PLAT=t9130 clean
make -j"${PARALLEL}" USE_COHERENT_MEM=0 LOG_LEVEL=20 PLAT=t9130 MV_DDR_PATH=../mv-ddr-marvell CP_NUM=$CP_NUM all fip
popd

dd if=/dev/zero of=spi.img bs=8M count=1
dd if=build/arm-trusted-firmware/build/t9130/release/flash-image.bin of=spi.img conv=notrunc
cp spi.img /out/spi.img
