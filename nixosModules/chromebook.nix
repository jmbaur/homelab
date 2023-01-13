{ config, lib, pkgs, ... }:
{
  options.hardware.chromebook.enable = lib.mkEnableOption "chromebook";
  config = lib.mkIf config.hardware.chromebook.enable {
    services.xserver.xkbOptions = "ctrl:swap_lwin_lctl";
    services.xserver.xkbModel = "chromebook";
    programs.flashrom = {
      enable = true;
      package = pkgs.flashrom-cros;
    };
    # TODO(jared): extlinux-compatible bootloader generation does not include this
    specialisation.flashfriendly.configuration.boot.kernelParams = [ "iomem=relaxed" ];
  };
}
