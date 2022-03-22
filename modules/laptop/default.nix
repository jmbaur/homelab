{ config, lib, pkgs, ... }:
let
  cfg = config.custom.laptop;
in
{
  options.custom.laptop.enable = lib.mkEnableOption "Enable laptop configs";
  config = lib.mkIf cfg.enable {
    services.autorandr.enable = true;
    services.xserver.libinput.touchpad = {
      tapping = true;
      naturalScrolling = true;
      disableWhileTyping = true;
      accelProfile = "flat";
    };
  };
}
