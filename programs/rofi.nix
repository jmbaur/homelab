{ config, pkgs, ... }: {
  home-manager.users.jared.programs.rofi = {
    enable = true;
    font = "Hack 12";
    # plugins = with pkgs; [ rofi-file-browser rofi-power-menu ];
    extraConfig = {
      modi = "drun,ssh,run";
      kb-primary-paste = "Control+V,Shift+Insert";
      kb-secondary-paste = "Control+v,Insert";
    };
    terminal = "kitty";
  };
}
