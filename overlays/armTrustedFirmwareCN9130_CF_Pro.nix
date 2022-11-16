{ buildArmTrustedFirmware
, cn913x_build
, fetchFromGitHub
, fetchgit
, git
, symlinkJoin
, ubootCN9130_CF_Pro
, ...
}:
(buildArmTrustedFirmware rec {
  platform = "t9130";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "build/${platform}/release/flash-image.bin" ];
  extraMakeFlags = [
    "USE_COHERENT_MEM=0"
    "LOG_LEVEL=20"
    "MV_DDR_PATH=/tmp/mv_ddr_marvell"
    "CP_NUM=1" # clearfog pro
    "all"
    "fip"
  ];
}).overrideAttrs (old: rec {
  version = "00ad74c7afe67b2ffaf08300710f18d3dafebb45";
  src = fetchFromGitHub {
    owner = "ARM-software";
    repo = "arm-trusted-firmware";
    rev = version;
    sha256 = "sha256-kHI6H1yym8nWWmLMNOOLUbdtdyNPdNEvimq8EdW0nZw=";
  };
  nativeBuildInputs = old.nativeBuildInputs ++ [ git ];
  patches = old.patches ++ [
    "${cn913x_build}/patches/arm-trusted-firmware/0001-ddr-spd-read-failover-to-defualt-config.patch"
    "${cn913x_build}/patches/arm-trusted-firmware/0002-som-sdp-failover-using-crc-verification.patch"
  ];
  preBuild =
    let
      marvell-embedded-processors = fetchgit {
        leaveDotGit = true;
        url = "https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell";
        rev = "305d923e6bc4236cd3b902f6679b0aef9e5fa52d";
        sha256 = "sha256-d9tS0ajHGzVEi1XJzdu0dCvfeEHSPVCrfBqV8qLqC5c=";
      };
    in
    ''
      mkdir tmp
      cp -r ${marvell-embedded-processors} /tmp/mv_ddr_marvell
      chmod -R +w /tmp/mv_ddr_marvell
    '';
  BL33 = "${symlinkJoin {
            name = "armTrustedFirmwareCN9130_CF_Pro-BL33";
            paths = [ ubootCN9130_CF_Pro.src ubootCN9130_CF_Pro ];
          }}/u-boot.bin";
  SCP_BL2 = "${cn913x_build}/binaries/atf/mrvl_scp_bl2.img";
})

# make olddefconfig
# make -j${PARALLEL} DEVICE_TREE=$DTB_UBOOT
# cp $ROOTDIR/build/u-boot/u-boot.bin $ROOTDIR/binaries/u-boot/u-boot.bin
# export BL33=$ROOTDIR/binaries/u-boot/u-boot.bin
#
# echo "Building arm-trusted-firmware"
# cd $ROOTDIR/build/arm-trusted-firmware
# export SCP_BL2=$ROOTDIR/binaries/atf/mrvl_scp_bl2.img
#
# echo "Compiling U-BOOT and ATF"
# echo "CP_NUM=$CP_NUM"
# echo "DTB=$DTB_UBOOT"
#
# make PLAT=t9130 clean
# make -j${PARALLEL} USE_COHERENT_MEM=0 LOG_LEVEL=20 PLAT=t9130 MV_DDR_PATH=$ROOTDIR/build/mv-ddr-marvell CP_NUM=$CP_NUM all fip
#
# echo "Copying flash-image.bin to /Images folder"
# cp $ROOTDIR/build/arm-trusted-firmware/build/t9130/release/flash-image.bin $ROOTDIR/images/u-boot-${DTB_UBOOT}-${UBOOT_ENVIRONMENT}.bin
