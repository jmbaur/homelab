{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.kitty;

  tempus-themes = pkgs.fetchFromGitLab {
    owner = "protesilaos";
    repo = "tempus-themes";
    rev = "ac5aa5456d210c7b8444e6d61d751085147fd587";
    sha256 = "sha256-TPp/F3F5zfZoWO58gF/rjopDJ7YGzBcoSqiHoPQOVtI=";
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
      include ${tempus-themes}/kitty/tempus_night.conf
      term xterm-256color
      update_check_interval 0
    '';
  };
}
