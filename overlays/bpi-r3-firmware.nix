{ internalBoot ? true, writeText, fetchFromGitHub, buildUBoot, buildArmTrustedFirmware, buildPackages, dtc, openssl }:
let
  env = writeText "bpi-r3-uboot-env" ''
    // Linux mt6978a.dtsi defines the following reserved memory in the
    // first 256MB:
    // 0x4300_0000 - 0x4302_FFFF
    // 0x4FC0_0000 - 0x4FCF_FFFF
    // 0x4FD0_0000 - 0x4FD3_FFFF
    // 0x4FD4_0000 - 0x4FD7_FFFF
    // 0x4FD8_0000 - 0x4FDA_3FFF
    //
    // You need to be mindful of these when defining memory locations
    // for u-boot to use to boot the system, or these will clobber.

    bootm_size=0x10000000
    fdt_addr_r=0x43030000
    kernel_addr_r=0x43200000
    pxefile_addr_r=0x90100000
    ramdisk_addr_r=0x4b100000
    scriptaddr=0x90000000

    // Set initrd high to be under the reserved memory
    initrd_high=0x4fc00000

    // CONFIG_DEFAULT_FDT_FILE has quotes around path, which makes for an invalid path
    fdtfile=mediatek/mt7986a-bananapi-bpi-r3.dtb
  '';
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
    postPatch = ''
      cp ${env} board/mediatek/mt7986/mt7986-nixos.env
    '';
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

      CONFIG_BOOTSTD_DEFAULTS=y
      CONFIG_BOOTSTD_FULL=y
      CONFIG_CMD_BOOTFLOW_FULL=y
      CONFIG_USE_BOOTCOMMAND=y
      CONFIG_AUTOBOOT=y
      CONFIG_BOOTDELAY=1
      CONFIG_DISTRO_DEFAULTS=y
      CONFIG_ISO_PARTITION=y

      CONFIG_ENV_SOURCE_FILE="mt7986-nixos"
      CONFIG_DEFAULT_FDT_FILE="mediatek/mt7986a-bananapi-bpi-r3.dtb"
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
