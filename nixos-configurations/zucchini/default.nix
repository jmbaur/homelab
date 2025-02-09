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

      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.initrd.availableKernelModules = [
        "dwmac_rk"
        "nvme"
        "phy-rockchip-naneng-combphy"
        "rtc_hym8563"
      ];

      hardware.deviceTree = {
        enable = true;
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
        extraStructuredConfig = with lib.kernel; {
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
        (pkgs.extractLinuxFirmware "mali-firmware" [ "arm/mali/arch10.8/mali_csffw.bin" ])
      ];
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";
      custom.common.nativeBuild = true;
    }
    {
      nix.settings.allowed-uris = [
        "https://"
        "github:"
      ];

      services.hydra = {
        enable = true;
        hydraURL = "http://localhost:3000";
        notificationSender = "hydra@localhost";
        buildMachinesFiles = [ ];
        useSubstitutes = true;
      };
    }
  ];
}
