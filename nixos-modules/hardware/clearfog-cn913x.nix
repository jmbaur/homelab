{ config, lib, pkgs, ... }: {
  options.hardware.clearfog-cn913x = {
    enable = lib.mkEnableOption "clearfog-cn913x";
  };

  config = lib.mkIf config.hardware.clearfog-cn913x.enable {
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;

    boot.kernelParams = [ "console=ttyS0,115200" "cma=256M" ];

    boot.kernelPackages = pkgs.linuxPackages_5_15;
    boot.kernelPatches =
      let
        cn913x_build = pkgs.fetchFromGitHub {
          owner = "solidrun";
          repo = "cn913x_build";
          rev = "0a5047c2ed2c4095f404a457f38776e9a7d6d731";
          sha256 = "sha256-bViiPfpPYo/qScjI+CXJIiDKh2recXGGB4Bj1L9gQ5A=";
        };
      in
      [
        {
          name = "0001-arm64-dts-cn913x-add-cn913x-based-COM-express-type-";
          patch = "${cn913x_build}/patches/linux/0001-arm64-dts-cn913x-add-cn913x-based-COM-express-type-.patch";
        }
        {
          name = "0002-arm64-dts-cn913x-add-cn913x-COM-device-trees-to-the";
          patch = "${cn913x_build}/patches/linux/0002-arm64-dts-cn913x-add-cn913x-COM-device-trees-to-the.patch";
        }
        {
          name = "0004-dts-update-device-trees-to-cn913x-rev-1";
          patch = "${cn913x_build}/patches/linux/0004-dts-update-device-trees-to-cn913x-rev-1.1.patch";
        }
        {
          name = "0005-DTS-update-cn9130-device-tree";
          patch = "${cn913x_build}/patches/linux/0005-DTS-update-cn9130-device-tree.patch";
        }
        {
          name = "0007-update-spi-clock-frequency-to-10MHz";
          patch = "${cn913x_build}/patches/linux/0007-update-spi-clock-frequency-to-10MHz.patch";
        }
        {
          name = "0009-dts-cn9130-som-for-clearfog-base-and-pro";
          patch = "${cn913x_build}/patches/linux/0009-dts-cn9130-som-for-clearfog-base-and-pro.patch";
        }
        {
          name = "0010-dts-add-usb2-support-and-interrupt-btn";
          patch = "${cn913x_build}/patches/linux/0010-dts-add-usb2-support-and-interrupt-btn.patch";
        }
        {
          name = "0011-linux-add-support-cn9131-cf-solidwan";
          patch = "${cn913x_build}/patches/linux/0011-linux-add-support-cn9131-cf-solidwan.patch";
        }
        {
          name = "0012-linux-add-support-cn9131-bldn-mbv";
          patch = "${cn913x_build}/patches/linux/0012-linux-add-support-cn9131-bldn-mbv.patch";
        }
        {
          name = "0013-cpufreq-armada-enable-ap807-cpu-clk";
          patch = "${cn913x_build}/patches/linux/0013-cpufreq-armada-enable-ap807-cpu-clk.patch";
        }
        {
          name = "0014-thermal-armada-ap806-Thermal-values-updated";
          patch = "${cn913x_build}/patches/linux/0014-thermal-armada-ap806-Thermal-values-updated.patch";
        }
        {
          name = "0015-Documentation-bindings-armada-thermal-Added-armada-a";
          patch = "${cn913x_build}/patches/linux/0015-Documentation-bindings-armada-thermal-Added-armada-a.patch";
        }
        {
          name = "0016-thermal-armada-ap807-Thermal-data-structure-added";
          patch = "${cn913x_build}/patches/linux/0016-thermal-armada-ap807-Thermal-data-structure-added.patch";
        }
        {
          name = "0017-dts-armada-ap807-updated-thermal-compatibility";
          patch = "${cn913x_build}/patches/linux/0017-dts-armada-ap807-updated-thermal-compatibility.patch";
        }
        {
          name = "0018-DPDK-support-for-MVPP2";
          patch = "${cn913x_build}/patches/linux/0018-DPDK-support-for-MVPP2.patch";
        }
        {
          name = "0019-arm64-dts-cn9130-clearfog-base-add-m.2-gpios";
          patch = "${cn913x_build}/patches/linux/0019-arm64-dts-cn9130-clearfog-base-add-m.2-gpios.patch";
        }
        # {
        #   name = "0020-Switch-back-to-kernel-when-MUSDK-stops";
        #   patch = "${cn913x_build}/patches/linux/0020-Switch-back-to-kernel-when-MUSDK-stops.patch";
        # }
        {
          name = "0021-linux-cn9130-cf-solidwan-add-carrier-eeprom";
          patch = "${cn913x_build}/patches/linux/0021-linux-cn9130-cf-solidwan-add-carrier-eeprom.patch";
        }
        {
          name = "cn913x-additions";
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
        }
        {
          name = "minification";
          patch = null;
          extraStructuredConfig = with lib.kernel; {
            DRM = no;
            MEDIA_SUPPORT = no;
            SND = no;
            PANEL = no;
            SPEAKUP = no;
            FB = lib.mkForce no;
            INPUT_TOUCHSCREEN = no;
            INPUT_MISC = no;
          };
        }
      ];

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
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        LinkLocalAddressing = "no";
        BindCarrier = map (i: "lan${toString i}") [ 1 2 3 4 5 ];
      };
    };
  };
}
