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
      "org/settings-daemon/plugins/color" = {
        night-light-enabled = true;
      };
      "org/gnome/desktop/background" = {
        picture-uri = pkgs.nixos-artwork.wallpapers.simple-blue.gnomeFilePath;
      };
      "org/gnome/shell" = {
        enabled-extensions = [ "nightthemeswitcher@romainvigier.fr" ];
      };
      "org/gnome/shell/extensions/nightthemeswitcher/time" = {
        time-source = "nightlight";
      };
      "org/gnome/desktop/interface" = {
        show-battery-percentage = true;
        gtk-key-theme = "Emacs";
      };
      "org/gnome/desktop/input-sources" = {
        xkb-options = [ "ctrl:nocaps" ];
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
