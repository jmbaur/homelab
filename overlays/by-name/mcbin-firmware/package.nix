{
  buildArmTrustedFirmware,
  marvellBinaries,
  uboot-mvebu_mcbin-88f8040,
  uboot ? uboot-mvebu_mcbin-88f8040,
  mv-ddr-marvell,
}:

buildArmTrustedFirmware (finalAttrs: {
  platform = "a80x0_mcbin";

  patches = [ ./marvell-atf-no-git.patch ];

  preBuild = ''
    cp -r ${mv-ddr-marvell} ./mv_ddr_marvell
    chmod -R +w ./mv_ddr_marvell
  '';

  makeFlags = [
    "SCP_BL2=${marvellBinaries}/mrvl_scp_bl2.img"
    "BL33=${uboot}/u-boot.bin"
    "MV_DDR_PATH=./mv_ddr_marvell"
    "LOG_LEVEL=20"
    "MARVELL_SECURE_BOOT=0"
    "all"
    "fip"
    "mrvl_flash"
  ];

  enableParallelBuilding = true;

  filesToInstall = [ "build/${finalAttrs.platform}/release/flash-image.bin" ];

  meta.platforms = [ "aarch64-linux" ];
})
