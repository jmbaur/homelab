{ fetchFromGitHub
, buildArmTrustedFirmware
, buildPackages
, dtc
, openssl
, symlinkJoin
, uboot-mt7986a_bpir3_emmc
, ubootLib
}:

let
  uboot = uboot-mt7986a_bpir3_emmc.override {
    extraStructuredConfig = with ubootLib; {
      BOOTSTD_FULL = yes;
      MTD = yes;
      DM_MTD = yes;
      SPI = yes;
      DM_SPI = yes;
      MTD_SPI_NAND = yes;
      CMD_MTD = yes;
    };
  };
in
buildArmTrustedFirmware rec {
  platform = "mt7986";
  version = builtins.substring 0 7 src.rev;
  # mt7986 not in upstream ATF yet
  src = fetchFromGitHub {
    owner = "mtk-openwrt";
    repo = "arm-trusted-firmware";
    rev = "0ea67d76ae8be127c91caa3fcdf449b1fe533175";
    hash = "sha256-mlAzGRcqpLgWO3TmkrFvdFFmun+KiE+8FxGuqz+TKtI=";
  };
  nativeBuildInputs = [ dtc openssl ];
  extraMakeFlags = [
    "OPENSSL_DIR=${symlinkJoin { name = "openssl-dir"; paths = with buildPackages.openssl; [ out bin ]; }}"
    "BL33=${uboot}/u-boot.bin"
    "DRAM_USE_DDR4=1"
    # defines where the FIP image lives
    "BOOT_DEVICE=spim-nand"
    "all"
    "fip"
  ];
  filesToInstall = [ "build/${platform}/release/bl2.img" "build/${platform}/release/fip.bin" ];
  extraMeta.platforms = [ "aarch64-linux" ];
}
