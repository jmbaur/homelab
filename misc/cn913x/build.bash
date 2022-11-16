# shellcheck shell=bash

set -o errexit
set -o nounset
set -o pipefail

export UBOOT_ENVIRONMENT="spi"
export CP_NUM=1
export DTB_UBOOT="cn9130-cf-pro"
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64
export SHALLOW_FLAG="--depth 1"
export PATH=$PWD/build/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin:$PATH

BOOT_LOADER=${BOOT_LOADER:-u-boot}
CP_NUM=${CP_NUM:-1}
PARALLEL=$(getconf _NPROCESSORS_ONLN)

mkdir -p build
pushd build

mkdir -p toolchain
pushd toolchain
wget http://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
tar -xvf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
popd

git clone https://github.com/ARM-software/arm-trusted-firmware.git arm-trusted-firmware
pushd arm-trusted-firmware
git checkout 00ad74c7afe67b2ffaf08300710f18d3dafebb45
git am ../../patches/arm-trusted-firmware/*.patch
popd

git clone https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell.git mv-ddr-marvell
pushd mv-ddr-marvell
git checkout mv-ddr-devel
git am ../../patches/mv-ddr-marvell/*.patch
popd

git clone git://git.denx.de/u-boot.git u-boot
pushd u-boot
git checkout v2019.10 -b marvell
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

pushd build/arm-trusted-firmware
export SCP_BL2=$PWD/binaries/atf/mrvl_scp_bl2.img
make PLAT=t9130 clean
make -j"${PARALLEL}" USE_COHERENT_MEM=0 LOG_LEVEL=20 PLAT=t9130 MV_DDR_PATH=build/mv-ddr-marvell CP_NUM=$CP_NUM all fip
popd

cp build/arm-trusted-firmware/build/t9130/release/flash-image.bin /out/u-boot-${DTB_UBOOT}-${UBOOT_ENVIRONMENT}.bin
