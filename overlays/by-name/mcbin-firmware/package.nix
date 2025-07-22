{
  buildArmTrustedFirmware,
  marvellBinaries,
  uboot-mvebu_mcbin-88f8040,
  mv-ddr-marvell,
}:

buildArmTrustedFirmware rec {
  platform = "a80x0_mcbin";

  patches = [ ./marvell-atf-no-git.patch ];

  preBuild = ''
    cp -r ${mv-ddr-marvell} ./mv_ddr_marvell
    chmod -R +w ./mv_ddr_marvell
  '';

  extraMakeFlags = [
    "SCP_BL2=${marvellBinaries}/mrvl_scp_bl2.img"
    "BL33=${uboot-mvebu_mcbin-88f8040}/u-boot.bin"
    "MV_DDR_PATH=./mv_ddr_marvell"
    "LOG_LEVEL=20"
    "MARVELL_SECURE_BOOT=0"
    "all"
    "fip"
    "mrvl_flash"
  ];

  enableParallelBuilding = true;

  filesToInstall = [ "build/${platform}/release/flash-image.bin" ];
}
