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
  };
}
