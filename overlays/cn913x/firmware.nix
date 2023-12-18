{ spi ? false
, buildPackages
, fetchFromGitHub
, runCommand
, buildUBoot
, buildArmTrustedFirmware
, symlinkJoin
, marvellBinaries
, mvDdrMarvell
}:
let
  uboot =
    (buildUBoot {
      defconfig = "sr_cn913x_cex7_defconfig";
      version = "2023.07.02";
      src = fetchFromGitHub {
        owner = "jmbaur";
        repo = "u-boot";
        rev = "20048d16c8587f976a670af8b029dbace003e1b7"; # branch "cn913x"
        hash = "sha256-WvLwWdJylWAW3eLyUPVhVhiPbmsBz6dPrbjWrCjHgY4=";
      };
      extraMakeFlags = [ "DEVICE_TREE=cn9130-cf-pro" ];
      extraConfig =
        (if spi then ''
          CONFIG_ENV_IS_IN_MMC=n
          CONFIG_ENV_IS_IN_SPI_FLASH=y
          CONFIG_ENV_SIZE=0x10000
          CONFIG_ENV_OFFSET=0x3f0000
          CONFIG_ENV_SECT_SIZE=0x10000
        '' else ''
          CONFIG_ENV_IS_IN_MMC=y
          CONFIG_SYS_MMC_ENV_DEV=1
          CONFIG_SYS_MMC_ENV_PART=0
          CONFIG_ENV_IS_IN_SPI_FLASH=n
        '');
      filesToInstall = [ "u-boot.bin" ];
    }).overrideAttrs (_: { patches = [ ]; });

  atf = (buildArmTrustedFirmware rec {
    platform = "t9130";

    patches = [ ./atf-enablement.patch ];

    preBuild = ''
      cp -r ${mvDdrMarvell} /tmp/mv_ddr_marvell
      chmod -R +w /tmp/mv_ddr_marvell
    '';

    extraMakeFlags = [
      "SCP_BL2=${marvellBinaries}/mrvl_scp_bl2.img"
      "BL33=${uboot}/u-boot.bin"
      "USE_COHERENT_MEM=0"
      "MV_DDR_PATH=/tmp/mv_ddr_marvell"
      "CP_NUM=1" # cn9130-cf-pro
      "LOG_LEVEL=20"
      "MARVELL_SECURE_BOOT=0"
      "OPENSSL_DIR=${symlinkJoin { name = "openssl-dir"; paths = with buildPackages.openssl; [ out bin ]; }}"
      "all"
      "fip"
      "mrvl_flash"
    ];

    filesToInstall = [ "build/${platform}/release/flash-image.bin" ];
  }).overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ (with buildPackages; [
      git # mv-ddr-marvell
      openssl # fiptool
    ]);
  });
in
runCommand "cn9130-cf-pro-firmware.bin" { } (if spi then ''
  dd bs=1M count=8 if=/dev/zero of=$out
  dd conv=notrunc if=${atf}/flash-image.bin of=$out
'' else ''
  cp ${atf}/flash-image.bin $out
'')
