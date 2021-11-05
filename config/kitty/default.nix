{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.kitty;
in
{
  options = {
    custom.kitty = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.kitty ];
    environment.etc."xdg/kitty/kitty.conf".text = ''
      copy_on_select yes
      disable_ligatures always
      enable_audio_bell no
      font_family DejaVu Sans Mono
      font_size 14
      term xterm-256color
      update_check_interval 0
    '';
  };
}
