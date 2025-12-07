{
  config,
  lib,
  pkgs,
  ...
}:

let
  tinybootKernel = pkgs.linuxKernel.manualConfig {
    inherit (pkgs.linux_6_18) src version;
    configfile = ./tinyboot-linux.config;
  };

  tinyboot = pkgs.tinyboot.override {
    firmwareDirectory = pkgs.callPackage (
      { runCommand, zstd }:
      runCommand "tinyboot-pea-firmware" { nativeBuildInputs = [ zstd ]; } ''
        install -Dm0444 ${pkgs.linux-firmware}/lib/firmware/mediatek/mt8192/scp.img $out/lib/firmware/mediatek/mt8192/scp.img
      ''
    ) { };
  };

  fitImage = pkgs.callPackage (
    {
      runCommand,
      xz,
      dtc,
      ubootTools,
    }:
    runCommand "spherion-fitImage"
      {
        nativeBuildInputs = [
          xz
          dtc
          ubootTools
        ];
      }
      ''
        lzma --threads $NIX_BUILD_CORES <${tinybootKernel}/Image >kernel.lzma
        cp ${tinybootKernel}/dtbs/mediatek/mt8192-asurada-spherion-r0.dtb dtb
        cp ${tinyboot}/${tinyboot.initrdFile} initrd
        cp ${./tinyboot.its} image.its
        mkimage --fit image.its $out
      ''
  ) { };
in
{
  config = lib.mkMerge [
    {
      hardware.chromebook.asurada-spherion.enable = true;

      boot.loader.tinyboot.enable = true;

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "update-firmware" ''
          ${lib.getExe pkgs.flashrom} -p internal --write ${config.system.build.firmware}/coreboot.rom
        '')
      ];

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
    }
    {
      nixpkgs.buildPlatform = "x86_64-linux";
      custom.desktop.enable = false;
      custom.dev.enable = false;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-11f60000.mmc";
    }
    {
      # smaller cross desktop
      custom.basicNetwork.enable = true;
      networking.wireless.iwd.enable = true;
      custom.normalUser.enable = true;

      programs.firefox.enable = false;
      xdg.portal.enable = lib.mkForce false;
      services.speechd.enable = false;
    }
  ];
}
