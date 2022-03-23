{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options.custom.gui.enable = lib.mkEnableOption "Enable gui configs";
  config = lib.mkIf cfg.enable {
    home.sessionVariables.NIXOS_OZONE_WL = "1";
    home.packages = with pkgs; [
      bitwarden
      chromium
      element-desktop
      firefox-wayland
      obs-studio
      signal-desktop
      slack
      spotify
      teams
      virt-manager
      zoom-us
    ];

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    dconf.settings = {
      "org/gnome/desktop/input-sources" = {
        xkb-options = "[\"ctrl:nocaps\"]";
      };
      "org/gnome/desktop/interface" = {
        # gtk-theme = "Adwaita-dark";
        show-battery-percentage = true;
        gtk-key-theme = "Emacs";
      };
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
      };
    };

    programs.gnome-terminal = {
      enable = true;
      showMenubar = false;
      themeVariant = "system";
      profile.test = {
        visibleName = "test";
        audibleBell = false;
        default = true;
        # font = "Hack";
        showScrollbar = false;
      };
    };

  };
}
