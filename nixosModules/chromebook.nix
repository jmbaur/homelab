{ config, lib, pkgs, ... }:
{
  options.hardware.chromebook.enable = lib.mkEnableOption "chromebook";
  config = lib.mkIf config.hardware.chromebook.enable {
    services.xserver.xkbOptions = "ctrl:swap_lwin_lctl";
    programs.flashrom = {
      enable = true;
      package = pkgs.flashrom-cros;
    };
  };
}
