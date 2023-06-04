{ config, lib, pkgs, nixosConfig, ... }:
let
  cfg = config.custom.gui;
  guiData = import ../gui/data.nix;
in
with lib; {
  options.custom.gui.enable = mkOption {
    type = types.bool;
    default = nixosConfig.custom.gui.enable;
  };

  config = mkIf cfg.enable {
    home.pointerCursor = {
      package = pkgs.gnome-themes-extra;
      name = guiData.cursorTheme;
      size = mkDefault 24;
      x11.enable = true;
    };

    gtk = {
      enable = true;
      theme = { package = pkgs.gnome-themes-extra; name = guiData.gtkTheme; };
      iconTheme = { package = pkgs.gnome-themes-extra; name = guiData.gtkIconTheme; };
      gtk4 = removeAttrs config.gtk.gtk3 [ "bookmarks" "extraCss" "waylandSupport" ];
    };

    qt = {
      enable = true;
      platformTheme = "gtk";
      style = {
        package = pkgs.adwaita-qt;
        name = lib.toLower guiData.gtkTheme;
      };
    };

    services.mako = {
      enable = true;
      anchor = "top-right";
      defaultTimeout = 10000;
      font = "JetBrains Mono 12"; # ${toString config.wayland.windowManager.sway.config.fonts.names} ${toString config.wayland.windowManager.sway.config.fonts.size}";
      height = 1000;
      icons = true;
      layer = "overlay";
      width = 500;
    };

    xdg.configFile."sway/config".source = ./sway.config;
    xdg.configFile."kitty/kitty.conf".source = pkgs.writeText "kitty.conf" ''
      copy_on_select yes
      enable_audio_bell no
      font_family JetBrains Mono
      font_size 16
      include ${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Vivendi.conf
      shell_integration no-cursor
      tab_bar_style powerline
      update_check_interval 0
    '';

    # TODO(jared): make this config
    # swaynag = {
    #   enable = true;
    #   settings."<config>".font = "JetBrains Mono 12"; # ${toString config.wayland.windowManager.sway.config.fonts.names} ${toString config.wayland.windowManager.sway.config.fonts.size}";
    # };
  };
}
