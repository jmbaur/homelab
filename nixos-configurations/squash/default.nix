{
  config,
  lib,
  pkgs,
  ...
}:

let
  tinybootFitImage = pkgs.callPackage ./tinyboot-fit-image.nix {
    tinybootLinux = config.tinyboot.build.linux;
    fdt = "${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}";
  };

  tinybootFirmware = pkgs.callPackage ./firmware.nix {
    inherit (config.system.build) tinybootFitImage;
  };
in
{
  system.build = { inherit tinybootFitImage tinybootFirmware; };

  # better support for mt7915 wifi card
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  hardware.firmware = [
    pkgs.wireless-regdb
    (pkgs.extractLinuxFirmwareDirectory "mediatek")
  ];

  hardware.armada-388-clearfog.enable = true;

  hardware.deviceTree.name = "armada-388-clearfog-pro.dtb";

  boot.loader.systemd-boot.enable = false;
  tinyboot = {
    enable = true;
    linux.consoles = [ "ttyS0,115200n8" ];
    linux.kconfig = with lib.kernel; {
      # MACH_ARMADA_370 = yes;
      # MACH_ARMADA_375 = yes;
      # MACH_ARMADA_39X = yes;
      # MACH_ARMADA_XP = yes;
      AHCI_MVEBU = yes;
      ARCH_MVEBU = yes;
      I2C_MV64XXX = yes;
      MACH_ARMADA_38X = yes;
      MMC = yes;
      MMC_MVSDIO = yes;
      MMC_SDHCI = yes;
      MMC_SDHCI_PLTFM = yes;
      MMC_SDHCI_PXAV3 = yes;
      PCI_MVEBU = yes;
      PHY_MVEBU_A38X_COMPHY = yes;
      SATA_AHCI = yes;
      ATA_SFF = yes;
      ATA_BMDMA = yes;
      SATA_MV = yes;
      SERIAL_8250 = yes;
      SERIAL_8250_CONSOLE = yes;
      SERIAL_8250_DW = yes;
      SERIAL_OF_PLATFORM = yes;
      SPI_ORION = yes;
      USB_EHCI_ROOT_HUB_TT = yes;
      USB_XHCI_MVEBU = yes;
      RTC_DRV_ARMADA38X = yes;
      ARCH_MULTI_V7 = yes;
    };

    # CONFIG_SYSVIPC=y
    # CONFIG_HIGH_RES_TIMERS=y
    # CONFIG_LOG_BUF_SHIFT=14
    # CONFIG_PERF_EVENTS=y
    # CONFIG_SMP=y
    # CONFIG_HIGHMEM=y
    # CONFIG_ARM_APPENDED_DTB=y
    # CONFIG_ARM_ATAG_DTB_COMPAT=y
    # CONFIG_CPU_FREQ=y
    # CONFIG_CPUFREQ_DT=y
    # CONFIG_CPU_IDLE=y
    # CONFIG_ARM_MVEBU_V7_CPUIDLE=y
    # CONFIG_VFP=y
    # CONFIG_NEON=y
    # # CONFIG_COMPACTION is not set
    # CONFIG_MTD=y
    # CONFIG_MTD_CMDLINE_PARTS=y
    # CONFIG_MTD_BLOCK=y
    # CONFIG_MTD_CFI=y
    # CONFIG_MTD_CFI_INTELEXT=y
    # CONFIG_MTD_CFI_AMDSTD=y
    # CONFIG_MTD_CFI_STAA=y
    # CONFIG_MTD_PHYSMAP=y
    # CONFIG_MTD_PHYSMAP_OF=y
    # CONFIG_MTD_RAW_NAND=y
    # CONFIG_MTD_NAND_MARVELL=y
    # CONFIG_MTD_SPI_NOR=y
    # CONFIG_MTD_UBI=y
    # CONFIG_EEPROM_AT24=y
    # CONFIG_BLK_DEV_SD=y
    # CONFIG_ATA=y
    # CONFIG_MV643XX_ETH=y
    # CONFIG_MVNETA=y
    # CONFIG_MVPP2=y
    # CONFIG_SFP=y
    # CONFIG_MARVELL_PHY=y
    # CONFIG_INPUT_EVDEV=y
    # CONFIG_KEYBOARD_GPIO=y
    # CONFIG_I2C=y
    # CONFIG_I2C_CHARDEV=y
    # CONFIG_SPI=y
    # CONFIG_GPIO_SYSFS=y
    # CONFIG_GPIO_PCA953X=y
    # CONFIG_POWER_RESET=y
    # CONFIG_POWER_RESET_GPIO=y
    # CONFIG_POWER_SUPPLY=y
    # CONFIG_SENSORS_GPIO_FAN=y
    # CONFIG_SENSORS_PWM_FAN=y
    # CONFIG_THERMAL=y
    # CONFIG_ARMADA_THERMAL=y
    # CONFIG_WATCHDOG=y
    # CONFIG_ORION_WATCHDOG=y
    # CONFIG_REGULATOR=y
    # CONFIG_REGULATOR_FIXED_VOLTAGE=y
    # CONFIG_NOP_USB_XCEIV=y
    # CONFIG_NEW_LEDS=y
    # CONFIG_LEDS_CLASS=y
    # CONFIG_LEDS_GPIO=y
    # CONFIG_LEDS_TRIGGERS=y
    # CONFIG_LEDS_TRIGGER_TIMER=y
    # CONFIG_LEDS_TRIGGER_HEARTBEAT=y
    # CONFIG_RTC_CLASS=y
    # CONFIG_RTC_DRV_DS1307=y
    # CONFIG_RTC_DRV_PCF8563=y
    # CONFIG_RTC_DRV_S35390A=y
    # CONFIG_RTC_DRV_MV=y
    # CONFIG_RTC_DRV_ARMADA38X=y
    # CONFIG_DMADEVICES=y
    # CONFIG_MV_XOR=y
    # # CONFIG_IOMMU_SUPPORT is not set
    # CONFIG_MEMORY=y
    # CONFIG_PWM=y
  };

  custom = {
    server.enable = true;
    basicNetwork.enable = !config.router.enable;
    recovery.targetDisk = "/dev/disk/by-path/platform-f10a8000.sata-ata-1.0";
  };

  # Keep "wlan*" names for mt7915e card
  systemd.network.links."10-mt7915" = {
    matchConfig.Path = "platform-soc:pcie-pci-0000:01:00.0";
    linkConfig.NamePolicy = "kernel";
  };

  # hostapd tuning config for mt7915e
  services.hostapd = {
    radios.wlan0 = {
      band = "2g";
      countryCode = "US";
      wifi5.enable = false;
      wifi6.enable = false;
      wifi7.enable = false;
      wifi4 = {
        enable = true;
        capabilities = [
          "RXLDPC"
          "HT40+"
          "GF"
          "SHORT-GI-20"
          "SHORT-GI-40"
          "TX-STBC"
          "RX-STBC1"
          "MAX-AMSDU-7935"
        ];
      };
    };
    radios.wlan1 = {
      band = "5g";
      countryCode = "US";
      wifi7.enable = false;
      wifi4 = {
        enable = true;
        capabilities = [
          "RXLDPC"
          "HT40+"
          "GF"
          "SHORT-GI-20"
          "SHORT-GI-40"
          "TX-STBC"
          "RX-STBC1"
          "MAX-AMSDU-7935"
        ];
      };
      wifi5 = {
        enable = true;
        capabilities = [
          "MAX-MPDU-7991"
          "RXLDPC"
          "SHORT-GI-80"
          "TX-STBC-2BY1"
          "SU-BEAMFORMER"
          "SU-BEAMFORMEE"
          "MU-BEAMFORMER"
          "MU-BEAMFORMEE"
          "RX-ANTENNA-PATTERN"
          "TX-ANTENNA-PATTERN"
        ];
      };
      wifi6 = {
        enable = true;
        operatingChannelWidth = "80";
        singleUserBeamformer = true;
        singleUserBeamformee = true;
        multiUserBeamformer = true;
      };
    };
  };
}
