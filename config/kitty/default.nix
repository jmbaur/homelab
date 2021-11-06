{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.kitty;
  kitty-themes = pkgs.fetchFromGitHub {
    owner = "dexpota";
    repo = "kitty-themes";
    rev = "fca3335489bdbab4cce150cb440d3559ff5400e2";
    sha256 = "sha256-DBvkVxInRhKhx5S7dzz5bcSFCf1h6A27h+lIPIXLr4U=";
  };
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
      include ${kitty-themes}/themes/LiquidCarbonTransparent.conf
      term xterm-256color
      update_check_interval 0
    '';
  };

}
