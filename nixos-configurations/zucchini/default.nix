{ pkgs, lib, ... }:
{
  nixpkgs.hostPlatform = "aarch64-linux";

  custom.basicNetwork.enable = true;
  custom.dev.enable = true;
  custom.image.enable = true;
  custom.image.uefi.enable = true;
  custom.image.mutableNixStore = true;
  custom.image.primaryDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";
  custom.users.jared.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_testing;

  boot.initrd.availableKernelModules = [
    "phy-rockchip-naneng-combphy"
    "nvme"
  ];

  boot.kernelPatches = [
    {
      name = "zboot-compression";
      patch = null;
      extraStructuredConfig.EFI_ZBOOT = lib.kernel.yes;
    }
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
}
