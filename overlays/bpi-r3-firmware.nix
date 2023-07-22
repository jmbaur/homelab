{ internalBoot ? true, fetchFromGitHub, buildUBoot, buildArmTrustedFirmware, buildPackages, dtc, openssl }:
let
  uboot = (buildUBoot rec {
    version = "2023.07.02";
    src = fetchFromGitHub {
      owner = "u-boot";
      repo = "u-boot";
      rev = "v${version}";
      hash = "sha256-HPBjm/rIkfTCyAKCFvCqoK7oNN9e9rV9l32qLmI/qz4=";
    };
    filesToInstall = [ "u-boot.bin" ];
    # eMMC and SD are mutually exclusive on this board, choose one
    defconfig = "mt7986a_bpir3_${if internalBoot then "emmc" else "sd"}_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
    # these should be in the defconfig, but alas are not
    extraConfig = ''
      CONFIG_CMD_DM=y
      CONFIG_CMD_MTD=y
      CONFIG_CMD_SF=y
      CONFIG_CMD_SPI=y
      CONFIG_CMD_USB=y

      CONFIG_DM_MTD=y
      CONFIG_DM_SPI=y
      CONFIG_DM_SPI_FLASH=y
      CONFIG_DM_USB=y
      CONFIG_MTD=y
      CONFIG_MTD_SPI_NAND=y
      CONFIG_MTK_SPIM=y
      CONFIG_PHY=y
      CONFIG_PHY_MTK_TPHY=y
      CONFIG_SPI=y
      CONFIG_USB=y
      CONFIG_USB_XHCI_HCD=y
      CONFIG_USB_XHCI_MTK=y

      CONFIG_FIT=y
      CONFIG_FIT_SIGNATURE=y
      CONFIG_RSA=y

      CONFIG_BLK=y
      CONFIG_CMD_BOOTEFI=y
      CONFIG_EFI_LOADER=y
      CONFIG_PARTITIONS=y

      CONFIG_ENV_IS_NOWHERE=y

      CONFIG_AUTOBOOT=y
      CONFIG_BOOTDELAY=1
      CONFIG_BOOTSTD_DEFAULTS=y
      CONFIG_BOOTSTD_FULL=y
      CONFIG_CMD_BOOTFLOW_FULL=y
      CONFIG_USE_BOOTCOMMAND=y
    '';
  }).overrideAttrs (_: {
    # omit nixpkpgs patches for u-boot
    patches = [ ];
  });
  atf = buildArmTrustedFirmware rec {
    version = builtins.substring 0 7 src.rev;
    # mt7986 not in upstream ATF yet
    src = fetchFromGitHub {
      owner = "mtk-openwrt";
      repo = "arm-trusted-firmware";
      rev = "abcbd12b3bc0500f74a9f3e6f27fb7566e23fc5d";
      hash = "sha256-DcneBABDvtb7DQTvcfAVaw61jqmdjFogXfuiYKtkVRk=";
    };
    nativeBuildInputs = [ dtc openssl ];
    platform = "mt7986";
    extraMakeFlags = [
      "OPENSSL_DIR=${buildPackages.openssl}"
      "BL33=${uboot}/u-boot.bin"
      "DRAM_USE_DDR4=1"
      # defines where the FIP image lives
      "BOOT_DEVICE=${if internalBoot then "spim-nand" else "sdmmc"}"
      "all"
      "fip"
    ];
    filesToInstall = [ "build/${platform}/release/bl2.img" "build/${platform}/release/fip.bin" ];
    extraMeta.platforms = [ "aarch64-linux" ];
  };
in
atf
