{ spi ? false
, buildPackages
, fetchFromGitHub
, fetchgit
, runCommand
, buildUBoot
, buildArmTrustedFirmware
, symlinkJoin
}:
let
  uboot = (buildUBoot {
    defconfig = "sr_cn913x_cex7_defconfig";
    version = "2023.07.02";
    src = fetchFromGitHub {
      owner = "jmbaur";
      repo = "u-boot";
      rev = "c384e8009c22e4567b43e8b0f10be599da64fc9a"; # branch "cn913x"
      hash = "sha256-c44ut+daUgsA0N4pJmpaamAT1vgie5SNJv9VZdtP+JQ=";
    };
    extraMakeFlags = [ "DEVICE_TREE=cn9130-cf-pro" ];
    extraConfig =
      if spi then ''
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
      '';
    filesToInstall = [ "u-boot.bin" ];
  }).overrideAttrs (_: { patches = [ ]; });

  marvellBinaries = fetchFromGitHub {
    owner = "MarvellEmbeddedProcessors";
    repo = "binaries-marvell";
    rev = "c6c529ea3d905a28cc77331964c466c3e2dc852e";
    hash = "sha256-zcOEfOCcaxuMJspMVYDtmijwyh8B1xULqmw5h08eIQs=";
  };

  mvDdrMarvell = fetchgit {
    leaveDotGit = true; # needed for ATF build process
    url = "https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell";
    rev = "bfcf62051be835f725005bb5137928f7c27b792e";
    hash = "sha256-ikAUTTlvSeyOqcMpwegD62z/SoM6A63iEFkxDUxiT3I=";
  };

  atf = (buildArmTrustedFirmware rec {
    platform = "t9130";

    env = {
      SCP_BL2 = "${marvellBinaries}/mrvl_scp_bl2.img";
      BL33 = "${uboot}/u-boot.bin";
    };

    preBuild = ''
      cp -r ${mvDdrMarvell} /tmp/mv_ddr_marvell
      chmod -R +w /tmp/mv_ddr_marvell
    '';

    extraMakeFlags = [
      "USE_COHERENT_MEM=0"
      "MV_DDR_PATH=/tmp/mv_ddr_marvell"
      "CP_NUM=1" # cn9130-cf-pro
      "OPENSSL_DIR=${symlinkJoin { name = "openssl-dir"; paths = with buildPackages.openssl; [ out bin ]; }}"
      "all"
      "fip"
    ];

    filesToInstall = [ "build/${platform}/release/fip.bin" ];
  }).overrideAttrs
    (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ (with buildPackages; [
        git # mv-ddr-marvell
        openssl # fiptool
      ]);
    });
in
runCommand "cn9130-cf-pro-firmware.bin" { } (if spi then ''
  dd bs=1M count=8 if=/dev/zero of=$out
  dd conv=notrunc if=${atf}/fip.bin of=$out
'' else ''
  cp ${atf}/fip.bin $out
'')
