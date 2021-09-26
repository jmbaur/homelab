{ pkgs, config, ... }: {
  programs.rofi = {
    enable = true;
    font = "DejaVu Sans Mono 10";
    extraConfig = {
      modi = "drun,ssh,run";
      kb-primary-paste = "Control+V,Shift+Insert";
      kb-secondary-paste = "Control+v,Insert";
    };
    terminal = "kitty";
  };
}
