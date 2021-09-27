{ config, pkgs, ... }:
let
  tempus-themes = builtins.fetchGit { url = "https://gitlab.com/protesilaos/tempus-themes"; ref = "master"; };
in
{
  programs.kitty = {
    enable = true;
    font = {
      package = pkgs.hack-font;
      name = "Hack";
      size = 14;
    };
    settings = {
      copy_on_select = true;
      enable_audio_bell = false;
      term = "xterm-256color";
      update_check_interval = 0;
    };
    extraConfig = ''
      include ${tempus-themes}/kitty/tempus_night.conf
    '';
  };
}
