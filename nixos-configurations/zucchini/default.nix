{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      boot.kernelPackages = pkgs.linuxPackages_testing;

      boot.initrd.availableKernelModules = [
        "dwmac_rk"
        "nvme"
        "phy-rockchip-naneng-combphy"
        "rtc_hym8563"
      ];

      hardware.deviceTree = {
        name = "rockchip/rk3588s-orangepi-5.dtb";
        overlays = [
          {
            name = "use-standard-baudrate";
            dtsText = ''
              /dts-v1/;
              /plugin/;

              / {
                compatible = "rockchip,rk3588s";
              };

              &{/chosen} {
                stdout-path = "serial2:115200n8";
              };
            '';
          }
        ];
      };

      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem pkg.pname [ "rkbin" ];
      system.build.firmware = pkgs.uboot-orangepi-5-rk3588s.override {
        artifacts = [ "u-boot-rockchip-spi.bin" ];
        structuredExtraConfig = with lib.kernel; {
          BAUDRATE = freeform 115200; # c'mon rockchip
          USE_PREBOOT = yes;
          PREBOOT = freeform "pci enum; usb start; nvme scan";
        };
      };

      environment.systemPackages = [
        pkgs.uboot-env-tools
        pkgs.mtdutils
        (pkgs.writeShellScriptBin "update-firmware" ''
          ${lib.getExe' pkgs.mtdutils "flashcp"} \
            --verbose \
            ${config.system.build.firmware}/u-boot-rockchip-spi.bin \
            /dev/mtd0
        '')
      ];

      hardware.firmware = [
        (pkgs.extractLinuxFirmwareDirectory "arm/mali")
      ];

      # vulkan doesn't work (yet)
      environment.variables.GSK_RENDERER = "gl";

      services.evremap.enable = false;
    }
    {
      custom.basicNetwork.enable = true;
      custom.normalUser.enable = true;
      custom.dev.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";

      services.tailscale.enable = true;
      networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ 22 ];
    }
  ];
}
