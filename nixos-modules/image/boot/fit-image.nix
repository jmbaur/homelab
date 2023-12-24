{ config, lib, pkgs, ... }:
let
  cfg = config.custom.image;

  # TODO(jared):
  # - need to be able to customize storage medium we load the fit image
  #   from, not hardcoded to mmc
  # - need to be able to customize the address in memory the fit image
  #   is loaded into
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
    image.repart.partitions.boot = {
      contents = {
        "/boot.scr".source = bootScriptImage;
        "/uImage.a".source = config.system.build.fitImage;
        "/uImage.b".source = config.system.build.fitImage;
      };
      repartConfig = {
        Type = "esp";
        Label = "BOOT";
        Format = "vfat";
        SizeMinBytes = "256M";
        SizeMaxBytes = "256M";
        SplitName = "-";
      };
    };
  };
}
