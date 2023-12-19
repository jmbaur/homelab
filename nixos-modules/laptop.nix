{ config, lib, ... }:
let
  cfg = config.custom.laptop;
in

{
  options.custom.laptop = with lib; {
    enable = mkEnableOption "laptop config";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.xkb.options = lib.mkDefault "ctrl:nocaps";

    custom.gui.enable = lib.mkDefault true;
  };
}
