{ buildArmTrustedFirmware
, marvellBinaries
, buildPackages
, uboot-mvebu_mcbin-88f8040
, mvDdrMarvell
}:

let
  atf = (buildArmTrustedFirmware rec {
    platform = "a80x0_mcbin";

    preBuild = ''
      cp -r ${mvDdrMarvell} /tmp/mv_ddr_marvell
      chmod -R +w /tmp/mv_ddr_marvell
    '';

    extraMakeFlags = [
      "SCP_BL2=${marvellBinaries}/mrvl_scp_bl2.img"
      "BL33=${uboot-mvebu_mcbin-88f8040}/u-boot.bin"
      "MV_DDR_PATH=/tmp/mv_ddr_marvell"
      "LOG_LEVEL=20"
      "MARVELL_SECURE_BOOT=0"
      "all"
      "fip"
      "mrvl_flash"
    ];

    env.NIX_CFLAGS_COMPILE = toString [ "-Wno-array-bounds" ];

    filesToInstall = [ "build/${platform}/release/flash-image.bin" ];
  }).overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ../marvell-atf-no-git.patch ];
    nativeBuildInputs = (old.nativeBuildInputs or [ ])
      ++ (with buildPackages; [ openssl ]);
  });
in
atf
