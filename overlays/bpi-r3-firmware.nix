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
    defconfig = if internalBoot then "mt7986a_bpir3_emmc_defconfig" else "mt7986a_bpir3_sd_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
  }).overrideAttrs (_: { patches = [ ]; });
  firmware = buildArmTrustedFirmware rec {
    version = builtins.substring 0 7 src.rev;
    src = fetchFromGitHub {
      owner = "mtk-openwrt";
      repo = "arm-trusted-firmware";
      rev = "7d930c29b19f0d742b154af2ce8bd4686aee03d0";
      hash = "sha256-v0XT37hfrPNvEtPbrlT6vDiqWIJuifYaqBctdhnMicI=";
    };
    nativeBuildInputs = [ dtc openssl ];
    platform = "mt7986";
    extraMakeFlags = [
      "OPENSSL_DIR=${buildPackages.openssl}"
      "BL33=${uboot}/u-boot.bin"
      "BOOT_DEVICE=${if internalBoot then "emmc" else "sdmmc"}"
      "DRAM_USE_DDR4=1"
      "all"
      "fip"
    ];
    filesToInstall = [ "build/${platform}/release/bl2.img" "build/${platform}/release/fip.bin" ];
    extraMeta.platforms = [ "aarch64-linux" ];
  };
in
firmware
