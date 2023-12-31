{ pkgs, ... }: {
  # {{{ TODO(jared): delete this
  users.allowNoPasswordLogin = true;
  users.users.root.password = "";
  # }}}

  nixpkgs.hostPlatform = "aarch64-linux";

  custom.crossCompile.enable = true;

  custom.image.enable = true;
  custom.image.primaryDisk = "/dev/nvme0n1";

  boot.kernelPackages = pkgs.linuxPackages_testing;

  hardware.deviceTree = {
    enable = true;
    name = "rockchip/rk3588s-orangepi-5.dtb";
    overlays = [{
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
    }];
  };

  system.build.firmware = pkgs.uboot-orangepi-5-rk3588s.override {
    debug = true;
    artifacts = [ "u-boot-rockchip-spi.bin" ];
    extraStructuredConfig = with pkgs.ubootLib; {
      BAUDRATE = freeform 115200; # c'mon rockchip
      ROCKCHIP_SPI_IMAGE = yes;
      USE_PREBOOT = yes;
      PREBOOT = freeform "pci enum; usb start; nvme scan";
    };
  };
}
