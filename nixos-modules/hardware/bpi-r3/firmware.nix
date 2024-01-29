{ fetchFromGitHub
, buildArmTrustedFirmware
, buildPackages
, dtc
, openssl
, symlinkJoin
, uboot-mt7986a_bpir3_emmc
, runCommand
, mtdutils
, formats
}:

let
  atf = buildArmTrustedFirmware rec {
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
      "BL33=${uboot-mt7986a_bpir3_emmc}/u-boot.bin"
      "DRAM_USE_DDR4=1"
      # defines where the FIP image lives
      "BOOT_DEVICE=spim-nand"
      "all"
      "fip"
    ];
    filesToInstall = [ "build/${platform}/release/bl2.img" "build/${platform}/release/fip.bin" ];
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
    ubootenv2 = ubootenv // {
      vol_id = 2;
      vol_name = "ubootenv2";
    };
  };
  ubiImage = runCommand "bpi-r3-ubi-image" { nativeBuildInputs = [ mtdutils ]; } ''
    mkdir -p $out
    ubinize -vv -o $out/ubi.img -m 2048 -p 128KiB ${ubinizeConfig}
  '';
in
symlinkJoin {
  name = "bpi-r3-firmware";
  paths = [ atf ubiImage ];
}
