{ pkgs, lib, ... }:
{
  nixpkgs.hostPlatform = {
    config = "aarch64-unknown-linux-gnu";
    linux-kernel = {
      name = "aarch64-multiplatform";
      DTB = true;
      baseConfig = "defconfig";
      preferBuiltin = true;
      autoModules = true;
      target = "vmlinuz.efi";
    };
    gcc.arch = "armv8-a";
  };

  custom.dev.enable = true;
  custom.normalUser.enable = true;
  custom.image = {
    boot.uefi.enable = true;
    installer.targetDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";
  };

  boot.kernelPackages = pkgs.linuxPackages_testing;

  boot.initrd.availableKernelModules = [
    "phy-rockchip-naneng-combphy"
    "nvme"
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
