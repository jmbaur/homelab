{ bc
, bison
, buildPackages
, cn913x_build
, dtc
, fetchFromGitHub
, fetchgit
, fetchurl
, flex
, gcc7Stdenv
, git
, gnutls
, lib
, libuuid
, ncurses
, openssl
, swig
, which
, ...
}:
let
  defconfig = "sr_cn913x_cex7_defconfig";
  extraMakeFlags = [ "DEVICE_TREE=cn9130-cf-pro" ];
  filesToInstall = [ "u-boot.bin" ];
  installDir = "$out";
  uboot = gcc7Stdenv.mkDerivation rec {
    pname = "uboot-${defconfig}";
    version = "2019.10";
    src = fetchurl {
      url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${version}.tar.bz2";
      hash = "sha256-jW1gcHOVIt0jbLpwVbhza/6StPrA6hitgJgpynlmcBQ=";
    };

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
    postPatch = ''
      patchShebangs tools
      patchShebangs arch/arm/mach-rockchip
    '';

    # prevent non-volatile memory environment from being used
    extraConfig = ''
      CONFIG_ENV_IS_NOWHERE=y
    '';

    nativeBuildInputs = [
      ncurses # tools/kwboot
      bc
      bison
      dtc
      flex
      openssl
      (buildPackages.python3.withPackages (p: [
        p.libfdt
        p.setuptools # for pkg_resources
      ]))
      swig
      which # for scripts/dtc-version.sh
    ];
    depsBuildBuild = [ buildPackages.gcc7Stdenv.cc ];

    buildInputs = [
      ncurses # tools/kwboot
      libuuid # tools/mkeficapsule
      gnutls # tools/mkeficapsule
    ];

    hardeningDisable = [ "all" ];

    enableParallelBuilding = true;

    makeFlags = [
      "DTC=dtc"
      "CROSS_COMPILE=${gcc7Stdenv.cc.targetPrefix}"
    ] ++ extraMakeFlags;

    passAsFile = [ "extraConfig" ];

    # Workaround '-idirafter' ordering bug in staging-next:
    #   https://github.com/NixOS/nixpkgs/pull/210004
    # where libc '-idirafter' gets added after user's idirafter and
    # breaks.
    # TODO(trofi): remove it in staging once fixed in cc-wrapper.
    preConfigure = ''
      export NIX_CFLAGS_COMPILE_BEFORE_${lib.replaceStrings ["-" "."] ["_" "_"] buildPackages.stdenv.hostPlatform.config}=$(<${buildPackages.gcc7Stdenv.cc}/nix-support/libc-cflags)
      export NIX_CFLAGS_COMPILE_BEFORE_${lib.replaceStrings ["-" "."] ["_" "_"] gcc7Stdenv.hostPlatform.config}=$(<${gcc7Stdenv.cc}/nix-support/libc-cflags)
    '';

    configurePhase = ''
      runHook preConfigure
      make ${defconfig}
      cat $extraConfigPath >> .config
      runHook postConfigure
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p ${installDir}
      cp ${lib.concatStringsSep " " filesToInstall} ${installDir}
      mkdir -p "$out/nix-support"
      ${lib.concatMapStrings (file: ''
        echo "file binary-dist ${installDir}/${builtins.baseNameOf file}" >> "$out/nix-support/hydra-build-products"
      '') filesToInstall}
      runHook postInstall
    '';

    dontStrip = true;
    meta.platforms = [ "aarch64-linux" ];
  };
  BL33 = "${uboot}/u-boot.bin";
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
    dd bs=1M count=8 if=/dev/zero of=$out/spi.img
    dd conv=notrunc if=build/${PLAT}/release/flash-image.bin of=$out/spi.img
  '';
}
