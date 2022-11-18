# shellcheck shell=bash

set -o errexit
set -o nounset
set -o pipefail

export UBOOT_ENVIRONMENT="spi"
export CP_NUM=1
export DTB_UBOOT="cn9130-cf-pro"
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

BOOT_LOADER=${BOOT_LOADER:-u-boot}
CP_NUM=${CP_NUM:-1}
PARALLEL=$(getconf _NPROCESSORS_ONLN)

pushd build

pushd arm-trusted-firmware
git am ../../patches/arm-trusted-firmware/*.patch
popd

pushd mv-ddr-marvell
git am ../../patches/mv-ddr-marvell/*.patch
popd

pushd u-boot
git am ../../patches/u-boot/*.patch
popd

popd

echo "Compiling U-BOOT and ATF"
echo "CP_NUM=$CP_NUM"
echo "DTB=$DTB_UBOOT"

pushd build/u-boot/
cp configs/sr_cn913x_cex7_defconfig .config
make olddefconfig
make -j"${PARALLEL}" DEVICE_TREE=$DTB_UBOOT
popd

cp build/u-boot/u-boot.bin binaries/u-boot/u-boot.bin
export BL33=$PWD/binaries/u-boot/u-boot.bin
export SCP_BL2=$PWD/binaries/atf/mrvl_scp_bl2.img

pushd build/arm-trusted-firmware
make PLAT=t9130 clean
make -j"${PARALLEL}" USE_COHERENT_MEM=0 LOG_LEVEL=20 PLAT=t9130 MV_DDR_PATH=../mv-ddr-marvell CP_NUM=$CP_NUM all fip
popd

dd if=/dev/zero of=spi.img bs=8M count=1
dd if=build/arm-trusted-firmware/build/t9130/release/flash-image.bin of=spi.img conv=notrunc
cp spi.img /out/spi.img
