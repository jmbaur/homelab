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
      nixpkgs.buildPlatform = "x86_64-linux";

      boot.kernelPackages = pkgs.linuxPackagesFor (
        pkgs.callPackage
          (
            { buildLinux, ... }@args:
            buildLinux (
              args
              // {
                version = "6.13.0";
                extraMeta.branch = "6.13";

                src = pkgs.fetchgit {
                  url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux";
                  # rk3588 branch
                  rev = "8af493584632ee57446659e26eae58192e8a80d7";
                  hash = "sha256-rqhRdaHM1aHMg2F5GK+Hd9NZ6Q5Bp9+QGK16kWGTGjE=";
                };
                kernelPatches = (args.kernelPatches or [ ]);
              }
              // (args.argsOverride or { })
            )
          )
          {
          }
      );

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
      custom.desktop.enable = true;
      custom.dev.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";
    }
  ];
}
