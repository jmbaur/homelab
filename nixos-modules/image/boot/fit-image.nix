{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  bootScript = pkgs.writeText "boot.cmd" ''
    if test -z $active; then
      setenv active a;
      saveenv
      echo no active partition set, using partition A
    fi

    setenv bootargs nixos.active=nixos-$active
    load ${cfg.ubootBootMedium.type} ${toString cfg.ubootBootMedium.index}:1 $loadaddr uImage.$active
    source ''${loadaddr}:bootscript
  '';

  bootScriptImage = pkgs.runCommand "boot.scr" { } ''
    ${lib.getExe' pkgs.buildPackages.ubootTools "mkimage"} \
      -A ${pkgs.stdenv.hostPlatform.linuxArch} \
      -O linux \
      -T script \
      -C none \
      -d ${bootScript} \
      $out
  '';
in
{
  config = lib.mkIf (cfg.bootVariant == "fit-image") {
    systemd.repart.partitions.boot = {
      Type = "esp";
      Label = "BOOT";
      Format = "vfat";
      SizeMinBytes = "256M";
      SizeMaxBytes = "256M";
      SplitName = "-";
    };
    image.repart.partitions.boot = {
      contents = {
        "/boot.scr".source = bootScriptImage;
        "/uImage.a".source = config.system.build.fitImage;
        "/uImage.b".source = config.system.build.fitImage;
      };
      repartConfig = config.systemd.repart.partitions.boot;
    };
  };
}
