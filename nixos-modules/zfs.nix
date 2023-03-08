{ config, lib, ... }:
let zfsDisabled = config.custom.disableZfs; in
{
  options.custom.disableZfs = lib.mkEnableOption "disable zfs suppport";
  config = lib.mkIf zfsDisabled {
    nixpkgs.overlays = [
      (_: super: {
        zfs = super.zfs.overrideAttrs (_: {
          meta.platforms = [ ];
        });
      })
    ];
  };
}
