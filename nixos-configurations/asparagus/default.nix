{ lib, pkgs, ... }:
let
  tinybootKernel = pkgs.linuxKernel.manualConfig {
    inherit (pkgs.linux_6_18) src version;
    configfile = ./tinyboot-linux.config;
  };

  fitImage = pkgs.callPackage (
    {
      runCommand,
      xz,
      dtc,
      ubootTools,
    }:
    runCommand "wormdingler-fitImage"
      {
        depsBuildBuild = [
          xz
          dtc
          ubootTools
        ];
      }
      ''
        lzma --threads $NIX_BUILD_CORES <${tinybootKernel}/Image >kernel.lzma
        cp ${tinybootKernel}/dtbs/qcom/sc7180-trogdor-wormdingler-rev1-boe.dtb dtb
        cp ${pkgs.tinyboot}/${pkgs.tinyboot.initrdFile} initrd
        cp ${./tinyboot.its} image.its
        mkimage --fit image.its $out
      ''
  ) { };
in
{
  config = lib.mkMerge [
    {
      hardware.deviceTree.name = "qcom/sc7180-trogdor-wormdingler-rev1-boe.dtb";

      hardware.chromebook.trogdor.enable = true;

      boot.loader.tinyboot.enable = true;
      system.build.firmware = pkgs.buildCoreboot {
        kconfig = ''
          CONFIG_BOARD_GOOGLE_SPHERION=y
          CONFIG_VENDOR_GOOGLE=y
          CONFIG_DEFAULT_CONSOLE_LOGLEVEL_5=y
          # CONFIG_PAYLOAD_NONE is not set
          CONFIG_PAYLOAD_FIT_SUPPORT=y
          CONFIG_PAYLOAD_FIT=y
          CONFIG_PAYLOAD_FILE="${fitImage}"
        '';
      };

      services.evremap.settings = {
        device_name = lib.mkForce "Google Inc. Hammer";
        phys = "usb-xhci-hcd.0.auto-1.3/input0";
      };
    }
    {
      custom.desktop.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-7c4000.mmc";
      nixpkgs.buildPlatform = "x86_64-linux";
    }
  ];
}
