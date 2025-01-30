{
  config,
  pkgs,
  lib,
  ...
}:

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
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";
    }
    {
      services.woodpecker-server = {
        enable = true;
        environment = {
          WOODPECKER_GRPC_ADDR = "[::]:9000";
          WOODPECKER_HOST = "${config.networking.hostName}.internal";
          WOODPECKER_METRICS_SERVER_ADDR = "[::]:9090";
          WOODPECKER_SERVER_ADDR = "[::]:8000";
        };
      };

      services.woodpecker-agents.agents.exec = {
        enable = true;

        environment = {
          WOODPECKER_SERVER = "[::1]:9000";
          WOODPECKER_BACKEND = "local";
        };

        path = [
          # Needed to clone repos
          pkgs.git
          pkgs.git-lfs
          pkgs.woodpecker-plugin-git
          # Used by the runner as the default shell
          pkgs.bash
          # Most likely to be used in pipeline definitions
          pkgs.coreutils
        ];
      };
    }
  ];
}
