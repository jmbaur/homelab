{ config, lib, pkgs, ... }: {
  options.hardware.clearfog-cn913x = {
    enable = lib.mkEnableOption "clearfog-cn913x";
  };

  config = lib.mkIf config.hardware.clearfog-cn913x.enable {
    system.build.firmware = pkgs.cn9130CfProSpiFirmware;

    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;

    boot.kernelParams = [ "console=ttyS0,115200" "cma=256M" ];

    boot.kernelPackages = pkgs.linuxPackages_5_15;
    boot.kernelPatches =
      # NOTE: patches that don't apply cleanly are commented out
      (map
        (patch: {
          name = lib.replaceStrings [ ".patch" ] [ "" ] (builtins.baseNameOf patch);
          inherit patch;
        }) [
        "${pkgs.cn913x_build_repo}/patches/linux/0001-cpufreq-armada-enable-ap807-cpu-clk.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0002-thermal-armada-ap806-Thermal-values-updated.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0003-Documentation-bindings-armada-thermal-Added-armada-a.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0004-thermal-armada-ap807-Thermal-data-structure-added.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0005-dts-armada-ap807-updated-thermal-compatibility.patch"
        # "${pkgs.cn913x_build_repo}/patches/linux/0006-net-sfp-add-support-for-a-couple-of-copper-multi-rat.patch"
        # "${pkgs.cn913x_build_repo}/patches/linux/0007-net-sfp-add-support-for-HXSX-ATRI-1-copper-SFP-modul.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0008-arm64-dts-cn913x-add-cn913x-based-COM-express-type-7.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0009-cn9130-som-for-clearfog-base-and-pro.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0010-linux-add-support-cn9131-cf-solidwan.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0011-linux-add-support-cn9131-bldn-mbv.patch"
        # "${pkgs.cn913x_build_repo}/patches/linux/0012-DPDK-support-for-MVPP2.patch"
        # "${pkgs.cn913x_build_repo}/patches/linux/0013-Switch-back-to-kernel-when-MUSDK-stops.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0014-linux-fix-5GB-ports-phy-support-cn9132.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0015-Add-phy-support-1G-eth-ports-Belden-cn9131.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0016-arm64-dts-cn9131-cf-solidwan-update-model-property-t.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0017-arm64-dts-cn9130-som-support-eeprom-replacement-part.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0018-arm64-dts-cn9131-cf-solidwan-add-alias-for-ethernet5.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0019-arm64-dts-cn9131-cf-solidwan-switch-cp0_phy0-to-auto.patch"
        "${pkgs.cn913x_build_repo}/patches/linux/0020-arm64-dts-cn9131-cf-solidwan-enable-only-cp0-rtc.patch"
      ]) ++ [{
        name = "cn913x-enablement";
        patch = null;
        extraStructuredConfig = with lib.kernel; {
          ACPI_CPPC_CPUFREQ = yes;
          ARM_ARMADA_8K_CPUFREQ = yes;
          CPU_FREQ_DEFAULT_GOV_ONDEMAND = yes;
          CPU_FREQ_GOV_CONSERVATIVE = yes;
          CPU_FREQ_GOV_POWERSAVE = yes;
          EEPROM_AT24 = yes;
          GPIO_SYSFS = yes;
          MARVELL_10G_PHY = yes;
          MARVELL_PHY = yes;
          NET_DSA = module;
          NET_DSA_MV88E6XXX = module;
          SENSORS_MCP3021 = yes;
          SENSORS_PWM_FAN = yes;
          SFP = yes;
          UIO = yes;
          USB_SERIAL = yes;
          USB_SERIAL_FTDI_SIO = yes;
          USB_SERIAL_OPTION = yes;
          USB_SERIAL_WWAN = yes;
        };
      }];

    hardware.deviceTree = {
      enable = true;
      filter = "cn913*.dtb";
    };

    systemd.network.links = {
      "10-wan" = {
        matchConfig.OriginalName = "eth2";
        linkConfig.Name = "wan";
      };
      "10-lan" = {
        matchConfig.OriginalName = "eth1";
        linkConfig.Name = "lan";
      };
      # 10Gbps link
      "10-sfpplus" = {
        matchConfig.OriginalName = "eth0";
        linkConfig.Name = "sfpplus";
      };
    };

    # Ensure the DSA master interface is bound to being up by it's slave
    # interfaces.
    systemd.network.networks.lan-master = {
      name = "lan";
      linkConfig.RequiredForOnline = false;
      networkConfig = {
        LinkLocalAddressing = "no";
        BindCarrier = map (i: "lan${toString i}") [ 1 2 3 4 5 ];
      };
    };
  };
}
