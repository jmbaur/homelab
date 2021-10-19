{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.kitty;

  kitty-themes = builtins.fetchTarball {
    url = "https://github.com/dexpota/kitty-themes/archive/fca3335489bdbab4cce150cb440d3559ff5400e2.tar.gz";
    sha256 = "11dgrf2kqj79hyxhvs31zl4qbi3dz4y7gfwlqyhi4ii729by86qc";
  };
in
{
  options = {
    custom.kitty = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable custom kitty setup.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ kitty ];
    environment.etc."xdg/kitty/kitty.conf".text = ''
      copy_on_select yes
      disable_ligatures always
      enable_audio_bell no
      font_family DejaVu Sans Mono
      font_size 14
      include ${kitty-themes}/themes/gruvbox_dark.conf
      term xterm-256color
      update_check_interval 0
    '';
  };
}
