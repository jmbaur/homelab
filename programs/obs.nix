{ config, pkgs, ... }: {
  home-manager.users.jared.programs.obs-studio = {
    enable = true;
    plugins = with pkgs; [ obs-v4l2sink ];
  };
}
