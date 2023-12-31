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
    custom.image.bootFileCommands = ''
      echo "${bootScriptImage}:/boot.scr"
      echo "${config.system.build.fitImage}:/uImage.a"
    '';
  };
}
