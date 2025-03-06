{
  spi ? true,
  buildArmTrustedFirmware,
  buildUBoot,
  fetchFromGitHub,
  lib,
  marvellBinaries,
  mv-ddr-marvell,
  openssl,
}:

let
  cn913x_build = fetchFromGitHub {
    owner = "SolidRun";
    repo = "cn913x_build";
    rev = "b2b056549ed87d418523e8d4557d50af3764e231";
    hash = "sha256-NBy4tiUjHmsKoJneidR8qcT9TyjA8ffVbWE+nkziW6M=";
  };

  uboot = buildUBoot {
    defconfig = "mvebu_db_cn91xx_defconfig";

    version = "2023.01";

    src = fetchFromGitHub {
      owner = "SolidRun";
      repo = "u-boot";
      rev = "u-boot-v2023.01-marvell-sdk-v12";
      hash = "sha256-sfrrGpvqlbfTvBkKxDjPwOD695paMIQRa7nIuY0CK7A=";
    };

    enableParallelBuilding = true;

    patches =
      map (file: "${cn913x_build}/patches/u-boot/${file}") [
        "0001-add-initial-support-for-solidrun-cn9130-som-based-bo.patch"
        "0002-net-mvpp2-support-10gbase-r-mode.patch"
        "0003-cmd-tlv_eeprom-support-specifying-tlv-eeprom-in-DT-a.patch"
        "0004-board-marvell-octeontx2_cn913x-support-building-with.patch"
        "0005-arch-arm-dts-cn9130-sr-som-define-tlv-eeproms.patch"
        "0006-mvebu-pinctrl-allow-probe-without-pin-func-dts-prope.patch"
        "0007-arch-arm-dts-cn9130-sr-som-convert-pinctrl-nodes-num.patch"
        "0008-HACK-arm-dts-armada-cp110-disambiguate-mdio-bus-name.patch"
        "0009-board-marvell-octeontx2_cn913x-fixup-cn9131-solidwan.patch"
        "0010-arch-arm-dts-cn9131-cf-solidwan-fix-sata-port-serdes.patch"
        "0011-arch-arm-dts-cn9131-cf-solidwan-fix-cp1-pcie-address.patch"
        "0012-arch-arm-dts-cn9130-sr-som-fix-comphy-configuration.patch"
        "0013-arm-dts-add-description-for-solidrun-cn9132-clearfog.patch"
        "0014-cmd-tlv_eeprom-export-tlvinfo_find_tlv-function-as-l.patch"
        "0015-board-marvell-octeontx2_cn913x-parse-fdtfile-from-tl.patch"
        "0016-arch-arm-dts-cn9130-sr-som-cn9130-sr-cex7-fix-utmi-p.patch"
        "0017-drivers-rtc-marvell-rename-priv_auto_alloc_size-to-p.patch"
        "0018-arch-arm-dts-cn9130-sr-som-cn9130-sr-cex7-fix-net-rt.patch"
        "0019-arch-arm-dts-cn9130-sr-som-cn9130-sr-cex7-fix-emmc-p.patch"
      ]
      ++ [ ./fix-compiler-warnings.patch ];

    passAsFile = [ "extraConfig" ];

    configurePhase = ''
      runHook preConfigure

      $BASH ./scripts/kconfig/merge_config.sh configs/$defconfig $extraConfigPath
      echo CONFIG_DEFAULT_DEVICE_TREE=\"cn9130-cf-pro\" >>.config
      make $makeFlags $olddefconfig

      runHook postConfigure
    '';

    extraConfig = (
      ''
        CONFIG_BOOTSTD_BOOTCOMMAND=y
        CONFIG_BOOTSTD_FULL=y
        CONFIG_CMD_VBE=n
        CONFIG_FIT=y
        CONFIG_SYS_BOOTM_LEN=0x${lib.toHexString (128 * 1024 * 1024)}
      ''
      + ''
        CONFIG_NET_RANDOM_ETHADDR=y
        CONFIG_I2C_EEPROM=y
        CONFIG_CMD_TLV_EEPROM=y
        CONFIG_ID_EEPROM=y
        CONFIG_LAST_STAGE_INIT=y
        CONFIG_GPIO_HOG=y
        CONFIG_PHY_MARVELL_10G=y
        CONFIG_DM_PCA953X=y
        CONFIG_DM_RTC=y
        CONFIG_MARVELL_RTC=y
        CONFIG_DM_REGULATOR_FIXED=y
        CONFIG_BUTTON=y
        CONFIG_BUTTON_GPIO=y
        CONFIG_CMD_GPIO=y
        CONFIG_LED=y
        CONFIG_LED_GPIO=y
        CONFIG_CMD_SNTP=y
        CONFIG_SUPPORT_EMMC_BOOT=y
      ''
      + (
        if spi then
          ''
            CONFIG_ENV_IS_IN_MMC=n
            CONFIG_ENV_IS_IN_SPI_FLASH=y
            CONFIG_ENV_SIZE=0x10000
            CONFIG_ENV_OFFSET=0x3f0000
            CONFIG_ENV_SECT_SIZE=0x10000
          ''
        else
          ''
            CONFIG_ENV_IS_IN_MMC=y
            CONFIG_SYS_MMC_ENV_DEV=1
            CONFIG_SYS_MMC_ENV_PART=0
            CONFIG_ENV_IS_IN_SPI_FLASH=n
          ''
      )
    );
    filesToInstall = [
      "u-boot.bin"
      ".config"
    ];
  };
in
(buildArmTrustedFirmware rec {
  platform = "t9130";

  patches =
    (map (file: "${./atf-patches}/${file}") [
      "0001-plat-marvell-octeontx-otx2-t91-t9130-ddr-configurati.patch"
      "0002-plat-marvell-armada-8k-add-support-for-early-gpio-ho.patch"
      "0003-plat-marvell-octeontx-otx2-t91-t9130-drive-fan-for-c.patch"
      "0004-plat-marvell-octeontx-otx2-t91-t9130-support-ddr-con.patch"
      "0005-plat-marvell-octeontx-otx2-t91-t9130-support-ddr-con.patch"
      "0006-plat-marvell-octeontx-otx2-t91-t9130-gix-gpio-direct.patch"
      "0007-plat-marvell-octeontx-otx2-t91-t9130-flush-i2c-bus-b.patch"
      "0008-plat-marvell-octeontx-otx2-t91-t9130-reorganise-i2c-.patch"
      "0009-plat-marvell-octeontx-otx2-t91-t9130-add-build-time-.patch"
    ])
    ++ [ ../mcbin-firmware/marvell-atf-no-git.patch ];

  preBuild = ''
    cp -r ${mv-ddr-marvell} mv_ddr_marvell
    chmod -R +w mv_ddr_marvell
  '';

  extraMakeFlags = [
    "SCP_BL2=${marvellBinaries}/mrvl_scp_bl2.img"
    "BL33=${uboot}/u-boot.bin"
    "USE_COHERENT_MEM=0"
    "MV_DDR_PATH=./mv_ddr_marvell"
    "CP_NUM=1" # cn9130-cf-pro
    "LOG_LEVEL=20"
    "MARVELL_SECURE_BOOT=0"
    "all"
    "fip"
    "mrvl_flash"
  ];

  filesToInstall = [ "build/${platform}/release/flash-image.bin" ];
}).overrideAttrs
  (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ openssl ];
  })
