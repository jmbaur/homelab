{
  buildArmTrustedFirmware,
  dtc,
  fetchFromGitHub,
  formats,
  lib,
  mtdutils,
  openssl,
  runCommand,
  symlinkJoin,
  uboot-mt7986a_bpir3_emmc,
  ubootTools,
  writeTextDir,
}:

let
  atf =
    (buildArmTrustedFirmware rec {
      platform = "mt7986";

      version = builtins.substring 0 7 src.rev;

      # mt7986 not in upstream ATF yet
      src = fetchFromGitHub {
        owner = "mtk-openwrt";
        repo = "arm-trusted-firmware";
        rev = "e090770684e775711a624e68e0b28112227a4c38";
        hash = "sha256-VI5OB2nWdXUjkSuUXl/0yQN+/aJp9Jkt+hy7DlL+PMg=";
      };

      strictDeps = true;

      patches =
        let
          openwrt = fetchFromGitHub {
            owner = "openwrt";
            repo = "openwrt";
            rev = "9ec32cfb2733856a2ab4caee07d9b3297568381d";
            hash = "sha256-casYMJNLavzZdPzCuh1xAR9iaLYG9TieVcYDNhIiHUQ=";
          };
        in
        map (file: "${openwrt}/package/boot/arm-trusted-firmware-mediatek/patches/${file}") [
          "0001-mediatek-snfi-FM35Q1GA-is-x4-only.patch"
          "0002-mediatek-snfi-adjust-pin-drive-strength-for-Fidelix-.patch"
          "0003-mediatek-snfi-adjust-drive-strength-to-12mA-like-old.patch"
          "0004-mediatek-snfi-fix-return-code-when-reading.patch"
        ];

      extraMakeFlags = [
        "BL33=${uboot-mt7986a_bpir3_emmc}/u-boot.bin"
        "BOOT_DEVICE=spim-nand" # defines where the FIP image lives
        "DRAM_USE_DDR4=1"
        "USE_MKIMAGE=1"
        "all"
        "fip"
      ];

      filesToInstall = [
        "build/${platform}/release/bl2.img"
        "build/${platform}/release/fip.bin"
      ];

      extraMeta.platforms = [ "aarch64-linux" ];
    }).overrideAttrs
      (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          dtc
          openssl
          ubootTools
        ];
      });

  ubiImage =
    runCommand "bpi-r3-ubi-image"
      {
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

        nativeBuildInputs = [ mtdutils ];
      }
      ''
        mkdir -p $out
        ubinize -vv -o $out/ubi.img -m 2048 -p 128KiB $ubinizeConfig
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
