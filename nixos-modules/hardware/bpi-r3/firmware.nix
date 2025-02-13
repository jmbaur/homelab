{
  buildArmTrustedFirmware,
  buildPackages,
  dtc,
  fetchFromGitHub,
  formats,
  lib,
  mtdutils,
  openssl,
  pkgsCross,
  runCommand,
  stdenv,
  symlinkJoin,
  uboot-mt7986a_bpir3_emmc,
  writeTextDir,
}:

let
  atf = buildArmTrustedFirmware rec {
    platform = "mt7986";
    version = builtins.substring 0 7 src.rev;
    # mt7986 not in upstream ATF yet
    src = fetchFromGitHub {
      owner = "mtk-openwrt";
      repo = "arm-trusted-firmware";
      rev = "bacca82a8cac369470df052a9d801a0ceb9b74ca";
      hash = "sha256-n5D3styntdoKpVH+vpAfDkCciRJjCZf9ivrI9eEdyqw=";
    };
    nativeBuildInputs = [
      dtc
      openssl
    ];
    # bromimage is a pre-built binary for x86_64-linux
    postPatch = ''
      echo -e '#!/bin/sh\n${pkgsCross.gnu64.stdenv.hostPlatform.emulator buildPackages} tools/mediatek/bromimage/bromimage-linux-x86_64 "$@"' >tools/mediatek/bromimage/bromimage
      chmod +x tools/mediatek/bromimage/bromimage
    '';
    enableParallelBuilding = true;
    extraMakeFlags = [
      "OPENSSL_DIR=${
        symlinkJoin {
          name = "openssl-dir";
          paths = with buildPackages.openssl; [
            out
            bin
          ];
        }
      }"
      "BL33=${uboot-mt7986a_bpir3_emmc}/u-boot.bin"
      "DRAM_USE_DDR4=1"
      "BOOT_DEVICE=spim-nand" # defines where the FIP image lives
      "all"
      "fip"
    ];
    filesToInstall = [
      "build/${platform}/release/bl2.img"
      "build/${platform}/release/fip.bin"
    ];
    extraMeta.platforms = [ "aarch64-linux" ];
  };
  ubinizeConfig = (formats.ini { }).generate "ubinize.ini" rec {
    ubootenv = {
      vol_id = 1;
      vol_name = "ubootenv";
      mode = "ubi";
      vol_type = "dynamic";
      vol_size = "0x1f000";
    };
    ubootenvred = ubootenv // {
      vol_id = 2;
      vol_name = "ubootenvred";
    };
  };
  ubiImage = runCommand "bpi-r3-ubi-image" { nativeBuildInputs = [ mtdutils ]; } ''
    mkdir -p $out
    ubinize -vv -o $out/ubi.img -m 2048 -p 128KiB ${ubinizeConfig}
  '';
in
symlinkJoin {
  name = "bpi-r3-firmware";
  paths = [
    (writeTextDir "README.md" (lib.fileContents ./README.md))
    atf
    ubiImage
  ];
}
