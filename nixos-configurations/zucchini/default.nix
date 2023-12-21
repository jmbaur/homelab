{ pkgs, ... }: {
  nixpkgs.hostPlatform = "aarch64-linux";

  custom.crossCompile.enable = true;

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
    extraStructuredConfig = with pkgs.ubootLib; {
      BAUDRATE = freeform 115200; # c'mon rockchip
    };
  };
}
