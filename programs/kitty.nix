{ config, pkgs, ... }:
let
  kitty-themes = builtins.fetchGit { url = "https://github.com/dexpota/kitty-themes"; ref = "master"; };
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
      include ${kitty-themes}/themes/gruvbox_dark.conf
    '';
  };
}
