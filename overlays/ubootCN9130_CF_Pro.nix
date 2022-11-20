{ buildUBoot
, buildPackages
, cn913x_build
, dtc
, fetchFromGitHub
, fetchgit
, fetchurl
, gcc7Stdenv
, git
, openssl
, symlinkJoin
, ...
}:
let
  uboot = (buildUBoot rec {
    version = "2019.10";
    src = fetchurl {
      url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${version}.tar.bz2";
      hash = "sha256-jW1gcHOVIt0jbLpwVbhza/6StPrA6hitgJgpynlmcBQ=";
    };
    extraMeta.platforms = [ "aarch64-linux" ];
    defconfig = "sr_cn913x_cex7_defconfig";
    # prevent non-volatile memory environment from being used
    extraConfig = ''
      CONFIG_ENV_IS_NOWHERE=y
    '';
    extraMakeFlags = [ "DEVICE_TREE=cn9130-cf-pro" ];
    filesToInstall = [ "u-boot.bin" ];
  }).overrideAttrs
    (_: {
      # nixpkgs has some patches for the raspberry pi that don't apply cleanly
      # to this rev of u-boot.
      patches = [
        "${cn913x_build}/patches/u-boot/0001-cmd-add-tlv_eeprom-command.patch"
        "${cn913x_build}/patches/u-boot/0002-cmd-tlv_eeprom.patch"
        "${cn913x_build}/patches/u-boot/0003-cmd-tlv_eeprom-remove-use-of-global-variable-current.patch"
        "${cn913x_build}/patches/u-boot/0004-cmd-tlv_eeprom-remove-use-of-global-variable-has_bee.patch"
        "${cn913x_build}/patches/u-boot/0005-cmd-tlv_eeprom-do_tlv_eeprom-stop-using-non-api-read.patch"
        "${cn913x_build}/patches/u-boot/0006-cmd-tlv_eeprom-convert-functions-used-by-command-to-.patch"
        "${cn913x_build}/patches/u-boot/0007-cmd-tlv_eeprom-remove-empty-function-implementations.patch"
        "${cn913x_build}/patches/u-boot/0008-cmd-tlv_eeprom-split-off-tlv-library-from-command.patch"
        "${cn913x_build}/patches/u-boot/0009-lib-tlv_eeprom-add-function-for-reading-one-entry-in.patch"
        "${cn913x_build}/patches/u-boot/0010-uboot-marvell-patches.patch"
        "${cn913x_build}/patches/u-boot/0011-uboot-support-cn913x-solidrun-paltfroms.patch"
        "${cn913x_build}/patches/u-boot/0012-add-SoM-and-Carrier-eeproms.patch"
        "${cn913x_build}/patches/u-boot/0013-find-fdtfile-from-tlv-eeprom.patch"
        "${cn913x_build}/patches/u-boot/0014-octeontx2_cn913x-support-distro-boot.patch"
        "${cn913x_build}/patches/u-boot/0015-octeontx2_cn913x-remove-console-variable.patch"
        "${cn913x_build}/patches/u-boot/0016-octeontx2_cn913x-enable-mmc-partconf-command.patch"
        "${cn913x_build}/patches/u-boot/0017-uboot-add-support-cn9131-cf-solidwan.patch"
        "${cn913x_build}/patches/u-boot/0018-uboot-add-support-bldn-mbv.patch"
        "${cn913x_build}/patches/u-boot/0019-uboot-cn9131-cf-solidwan-add-carrier-eeprom.patch"
        ./ramdisk_addr_r.patch
      ];
    });
  BL33 = "${symlinkJoin {
    name = "ubootCN9130_CF_Pro-with-src";
    paths = [ uboot.src uboot ];
  }}/u-boot.bin";
  SCP_BL2 = "${cn913x_build}/binaries/atf/mrvl_scp_bl2.img";
  PLAT = "t9130";
in
gcc7Stdenv.mkDerivation {
  inherit BL33 SCP_BL2;
  name = "ubootCN9130_CF_Pro";
  src = fetchFromGitHub {
    owner = "ARM-software";
    repo = "arm-trusted-firmware";
    rev = "00ad74c7afe67b2ffaf08300710f18d3dafebb45";
    sha256 = "sha256-kHI6H1yym8nWWmLMNOOLUbdtdyNPdNEvimq8EdW0nZw=";
  };
  patches = [
    "${cn913x_build}/patches/arm-trusted-firmware/0001-ddr-spd-read-failover-to-defualt-config.patch"
    "${cn913x_build}/patches/arm-trusted-firmware/0002-som-sdp-failover-using-crc-verification.patch"
  ];
  nativeBuildInputs = [ dtc git ];
  buildInputs = [ openssl ];
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
    "fip" # TODO(jared): not needed?
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
      cp -r ${marvell-embedded-processors} /tmp/mv_ddr_marvell
      chmod -R +w /tmp/mv_ddr_marvell
    '';
  installPhase = ''
    mkdir -p $out
    dd bs=8M count=1 if=/dev/zero of=spi.img
    dd conv=notrunc if=build/${PLAT}/release/flash-image.bin of=spi.img
    cp spi.img $out/
  '';
}
