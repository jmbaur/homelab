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
  uartBoot ? false,
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
        rev = "78a0dfd927bb00ce973a1f8eb4079df0f755887a"; # mtksoc-20250711 branch
        hash = "sha256-m9ApkBVf0I11rNg68vxofGRJ+BcnlM6C+Zrn8TfMvbY=";
      };

      strictDeps = true;
      enableParallelBuilding = true;

      extraMakeFlags = [
        "BL33=${uboot-mt7986a_bpir3_emmc}/u-boot.bin"
        "BOOT_DEVICE=${if uartBoot then "ram" else "spim-nand"}" # defines where the FIP image lives
        "DRAM_USE_DDR4=1"
        "USE_MKIMAGE=1"
        "all"
        "fip"
      ]
      ++ lib.optionals uartBoot [
        "RAM_BOOT_UART_DL=1"
      ];

      filesToInstall =
        if uartBoot then
          [ "build/${platform}/release/bl2.bin" ]
        else
          [ "build/${platform}/release/bl2.img" ]
          ++ [
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
