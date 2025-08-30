{
  spi ? true,
  buildArmTrustedFirmware,
  fetchFromGitHub,
  lib,
  makeUBoot,
  marvellBinaries,
  mv-ddr-marvell,
}:

let
  cn913x_build = fetchFromGitHub {
    owner = "SolidRun";
    repo = "cn913x_build";
    rev = "b2b056549ed87d418523e8d4557d50af3764e231";
    hash = "sha256-NBy4tiUjHmsKoJneidR8qcT9TyjA8ffVbWE+nkziW6M=";
  };

  uboot = makeUBoot {
    boardName = "mvebu_db_cn91xx";

    version = "2023.01";

    src = fetchFromGitHub {
      owner = "SolidRun";
      repo = "u-boot";
      rev = "u-boot-v2023.01-marvell-sdk-v12";
      hash = "sha256-sfrrGpvqlbfTvBkKxDjPwOD695paMIQRa7nIuY0CK7A=";
    };

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

    kconfig =
      with lib.kernel;
      {
        BOOTSTD_BOOTCOMMAND = yes;
        BOOTSTD_FULL = yes;
        CMD_VBE = unset;
        FIT = yes;
        SYS_BOOTM_LEN = freeform "0x${lib.toHexString (128 * 1024 * 1024)}";

        DEFAULT_DEVICE_TREE = freeform "cn9130-cf-pro";
        NET_RANDOM_ETHADDR = yes;
        I2C_EEPROM = yes;
        CMD_TLV_EEPROM = yes;
        ID_EEPROM = yes;
        LAST_STAGE_INIT = yes;
        GPIO_HOG = yes;
        PHY_MARVELL_10G = yes;
        DM_PCA953X = yes;
        DM_RTC = yes;
        MARVELL_RTC = yes;
        DM_REGULATOR_FIXED = yes;
        BUTTON = yes;
        BUTTON_GPIO = yes;
        CMD_GPIO = yes;
        LED = yes;
        LED_GPIO = yes;
        CMD_SNTP = yes;
        SUPPORT_EMMC_BOOT = yes;
      }
      // (
        if spi then
          {
            ENV_IS_IN_MMC = unset;
            ENV_IS_IN_SPI_FLASH = yes;
            ENV_SIZE = freeform "0x10000";
            ENV_OFFSET = freeform "0x3f0000";
            ENV_SECT_SIZE = freeform "0x10000";
          }
        else
          {
            ENV_IS_IN_MMC = yes;
            SYS_MMC_ENV_DEV = freeform 1;
            SYS_MMC_ENV_PART = freeform 0;
            ENV_IS_IN_SPI_FLASH = unset;
          }
      );

    artifacts = [ "u-boot.bin" ];
  };
in
buildArmTrustedFirmware (finalAttrs: {
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

  makeFlags = [
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

  filesToInstall = [ "build/${finalAttrs.platform}/release/flash-image.bin" ];

  passthru = { inherit uboot; };

  meta.platforms = [ "aarch64-linux" ];
})
