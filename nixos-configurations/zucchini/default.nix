{ pkgs, lib, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = {
        config = "aarch64-unknown-linux-gnu";
        linux-kernel = {
          name = "aarch64-multiplatform";
          DTB = true;
          baseConfig = "defconfig";
          preferBuiltin = true;
          autoModules = true;
          target = "Image";
        };
        gcc.arch = "armv8-a";
      };

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
          ROCKCHIP_SPI_IMAGE = yes;
          USE_PREBOOT = yes;
          PREBOOT = freeform "pci enum; usb start; nvme scan";
        };
      };

      hardware.firmware = [
        (pkgs.extractLinuxFirmware "mali-firmware" [ "arm/mali/arch10.8/mali_csffw.bin" ])
      ];
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.image = {
        mutableNixStore = true;
        boot.uefi.enable = true;
        installer.targetDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";
      };
    }
  ];
}
