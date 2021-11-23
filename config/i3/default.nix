{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.i3;
  cursorTheme = "Adwaita";
  cursorSize = "16";
in
{

  options = {
    custom.i3 = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    programs.xss-lock =
      let
        xsecurelock = pkgs.symlinkJoin {
          name = "xsecurelock";
          paths = [ pkgs.xsecurelock ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/xsecurelock \
              --set XSECURELOCK_FONT "Iosevka:size=14"
          '';
        };
      in
      {
        enable = true;
        extraOptions = [
          "-n"
          "${xsecurelock}/libexec/xsecurelock/dimmer"
          "-l"
        ];
        lockerCommand = "${xsecurelock}/bin/xsecurelock";
      };

    location.provider = "geoclue2";
    services.redshift.enable = true;

    services.clipmenu.enable = true;

    environment = {
      etc = {
        "dunst/dunstrc".source = ./dunstrc;
        "xdg/gtk-3.0/settings.ini".text = ''
          [Settings]
          gtk-application-prefer-dark-theme=1
          gtk-cursor-theme-name=${cursorTheme}
          gtk-cursor-theme-size=${cursorSize}
          gtk-key-theme-name=Emacs
          gtk-theme-name=Adwaita
        '';
      };
      variables = {
        XcursorTheme = cursorTheme;
        XcursorSize = cursorSize;
        XCURSOR_PATH = mkForce [
          "${pkgs.gnome.adwaita-icon-theme}/share/icons"
        ];
      };
    };

    services = {
      autorandr = {
        enable = true;
        defaultTarget = "laptop";
      };
      xserver = {
        enable = true;
        layout = "us";
        xkbOptions = "ctrl:nocaps";
        deviceSection = ''
          Option "TearFree" "true"
        '';
        displayManager = {
          lightdm.background = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
          defaultSession = "none+i3";
          autoLogin = { enable = true; user = "jared"; };
          sessionCommands = ''
            ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
              Xcursor.theme: ${cursorTheme}
              Xcursor.size: ${cursorSize}
              *.termName: xterm-256color
              *.vt100.faceName: DejaVu Sans Mono:size=14:antialias=true
              *.vt100.reverseVideo: true
            EOF
          '';
        };
        windowManager.i3 = {
          enable = true;
          extraSessionCommands = ''
            ${pkgs.hsetroot}/bin/hsetroot -cover ${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath}
          '';
          extraPackages = with pkgs; [
            brightnessctl
            dmenu
            dunst
            i3lock
            i3status
            libnotify
            pulseaudio
            scrot
          ];
          configFile = ./config;
        };
      };
    };
  };

}
