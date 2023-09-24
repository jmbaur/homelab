{ spi ? false
, cn913x_build_repo
, buildPackages
, dtc
, fetchFromGitHub
, fetchgit
, gcc7Stdenv
, git
, openssl
, runCommand
, buildUBoot
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

  BL33 = "${uboot}/u-boot.bin";
  SCP_BL2 = "${cn913x_build_repo}/binaries/atf/mrvl_scp_bl2.img";
  PLAT = "t9130";

  atf = gcc7Stdenv.mkDerivation rec {
    pname = "atf-cn9130-clearfog-pro";
    version = builtins.substring 0 7 src.rev;
    src = fetchFromGitHub {
      owner = "ARM-software";
      repo = "arm-trusted-firmware";
      rev = "00ad74c7afe67b2ffaf08300710f18d3dafebb45";
      sha256 = "sha256-kHI6H1yym8nWWmLMNOOLUbdtdyNPdNEvimq8EdW0nZw=";
    };
    patches = [
      "${cn913x_build_repo}/patches/arm-trusted-firmware/0001-ddr-spd-read-failover-to-defualt-config.patch"
      "${cn913x_build_repo}/patches/arm-trusted-firmware/0002-som-sdp-failover-using-crc-verification.patch"
    ];
    env = { inherit BL33 SCP_BL2; };
    nativeBuildInputs = [ openssl dtc git ];
    hardeningDisable = [ "all" ];
    dontStrip = true;
    depsBuildBuild = [ buildPackages.gcc7Stdenv.cc ];
    makeFlags = [
      "CROSS_COMPILE=${gcc7Stdenv.cc.targetPrefix}"
      # binutils 2.39 regression
      # `warning: /build/source/build/rk3399/release/bl31/bl31.elf has a LOAD segment with RWX permissions`
      # See also: https://developer.trustedfirmware.org/T996
      "LDFLAGS=-no-warn-rwx-segments"
      "PLAT=${PLAT}"
      "USE_COHERENT_MEM=0"
      "LOG_LEVEL=20"
      "MV_DDR_PATH=/tmp/mv_ddr_marvell"
      "CP_NUM=1" # cn9130-cf-pro
      "all"
      "fip"
    ];
    preBuild =
      let
        marvell-embedded-processors = fetchgit {
          leaveDotGit = true;
          branchName = "mv-ddr-devel";
          url = "https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell";
          rev = "305d923e6bc4236cd3b902f6679b0aef9e5fa52d";
          sha256 = "sha256-mgI84gDdzGLBzKaIyu7c/EtpFcUGEI+uNtYJfhzRd8U=";
        };
      in
      ''
        cp -r ${marvell-embedded-processors} /tmp/mv_ddr_marvell
        chmod -R +w /tmp/mv_ddr_marvell
      '';
    installPhase = ''
      mkdir -p $out
      cp build/${PLAT}/release/flash-image.bin $out
    '';
    meta.platforms = [ "aarch64-linux" ];
  };
in
runCommand "cn9130-cf-pro-firmware.bin" { } (if spi then ''
  dd bs=1M count=8 if=/dev/zero of=$out
  dd conv=notrunc if=${atf}/flash-image.bin of=$out
'' else ''
  cp ${atf}/flash-image.bin $out
'')
