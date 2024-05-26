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
      # TODO(jared): requires https://github.com/NixOS/nixpkgs/pull/277975
      target = "Image"; # "vmlinuz.efi"
    };
    gcc.arch = "armv8-a";
  };

  custom.basicNetwork.enable = true;
  custom.dev.enable = true;
  custom.image.enable = true;
  custom.image.boot.uefi.enable = true;
  custom.image.mutableNixStore = true;
  custom.image.installer.targetDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";

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
    {
      name = "correct-gpio_pwrctrl1-typos-on";
      patch = pkgs.fetchpatch {
        url = "https://github.com/torvalds/linux/commit/d7f2039e5321636069baa77ef2f1e5d22cb69a88.patch";
        hash = "sha256-7pOrOZx/OnaPzVV6jumRxN4/ZL7KIa8m4IXfA2mow6I=";
      };
    }
    {
      name = "Enable-GPU-on-Orange-Pi-5";
      patch = pkgs.fetchpatch {
        url = "https://github.com/torvalds/linux/commit/8beafb228f2be5de03e73178ac1081847d0d411f.patch";
        hash = "sha256-Z3K+qL9aRTzBhAI3RhO0va27oxbxegVe11JACaB9Re4=";
      };
    }
    {
      name = "add-USB-C-support-to-rk3588s-orangepi-5";
      patch = pkgs.fetchpatch {
        url = "https://github.com/torvalds/linux/commit/c57d1a970275aabfbfab4c56001394ada3456d8e.patch";
        hash = "sha256-WNSgdzjOqXwMVQQcn84K4CPB3oguh4Dt/DooUsVdpZQ=";
      };
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
