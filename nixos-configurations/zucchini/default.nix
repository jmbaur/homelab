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

      boot.kernelPackages = pkgs.linuxPackages_7_2;
      boot.kernelPatches =
        lib.mapAttrsToList
          (
            name:
            lib.const {
              name = lib.removeSuffix ".patch" name;
              patch = ./${name};
            }
          )
          (
            lib.filterAttrs (
              name: entryType:
              entryType == "regular"
              && lib.hasSuffix ".patch" name
              && name != "0005-media-rkisp2-Add-statistics-capture-video-node.patch"
              && name != "rockchip-cif.patch"
            ) (lib.readDir ./.)
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
          {
            name = baseNameOf ./rk3588-ov13855-c3.dtso;
            dtsFile = ./rk3588-ov13855-c3.dtso;
          }
        ];
      };

      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem pkg.pname [ "rkbin" ];
      system.build.firmware = pkgs.makeUBoot {
        boardName = "orangepi-5-rk3588s";
        artifacts = [ "u-boot-rockchip-spi.bin" ];
        makeFlags = [
          "BL31=${pkgs.armTrustedFirmwareRK3588}/bl31.elf"
          "ROCKCHIP_TPL=${pkgs.rkbin.TPL_RK3588}"
        ];
        meta.platforms = [ "aarch64-linux" ];
        kconfig = with lib.kernel; {
          BAUDRATE = freeform 115200; # c'mon rockchip
          USE_PREBOOT = yes;
          PREBOOT = freeform "pci enum; usb start; nvme scan";
        };
      };

      hardware.graphics.enable = true;

      environment.systemPackages = [
        pkgs.ffmpeg-headless
        pkgs.gpio-utils
        pkgs.i2c-tools
        pkgs.libgpiod
        pkgs.mediamtx
        pkgs.mtdutils
        pkgs.uboot-env-tools
        pkgs.v4l-utils
        (pkgs.libcamera.overrideAttrs (old: {
          nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.pkgsBuildHost.addDriverRunpath ];
          patches = (old.patches or [ ]) ++ [ ./rockchip-cif.patch ];
        }))
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
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-a41000000.pcie-pci-0004:41:00.0-nvme-1";
    }
  ];
}
