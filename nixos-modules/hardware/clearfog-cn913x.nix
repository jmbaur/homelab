{ config, lib, pkgs, ... }:
let
  cn913xBuildRepo = pkgs.fetchFromGitHub {
    owner = "solidrun";
    repo = "cn913x_build";
    rev = "d6d0577e6b6e86d29837618e9a02f5ee4ac136cb";
    hash = "sha256-5PGu7XQxtg0AP9RovDDqmPuVnrNQow1bYaorAmUFQ7Q=";
  };
  cn913xLinuxPatchesPath = "${cn913xBuildRepo}/patches/linux";
in
{
  options.hardware.clearfog-cn913x = {
    enable = lib.mkEnableOption "clearfog-cn913x";
  };

  config = lib.mkIf config.hardware.clearfog-cn913x.enable {
    system.build.firmware = pkgs.cn9130CfProSpiFirmware;

    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;

    boot.kernelParams = [ "console=ttyS0,115200" "cma=256M" ];

    boot.kernelPackages = pkgs.linuxPackages_6_1;
    boot.kernelPatches = (map
      (patch: {
        name = lib.replaceStrings [ ".patch" ] [ "" ] patch;
        patch = "${cn913xLinuxPatchesPath}/${patch}";
      })
      (lib.attrNames (lib.filterAttrs (_: entry: entry == "regular") (builtins.readDir cn913xLinuxPatchesPath))))
    ++ [{
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
