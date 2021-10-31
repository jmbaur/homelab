{ config, lib, pkgs, ... }:
with lib;
let

  cfg = config.custom.awesome;

in
{

  options = {
    custom.awesome = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      laptop = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {

    fonts.fonts = with pkgs; [
      dejavu_fonts
      hack-font
      inconsolata
      liberation_ttf
      noto-fonts
      noto-fonts-emoji
      source-code-pro
    ];

    environment = {
      etc = {
        "xdg/awesome/rc.lua".source = ./rc.lua;
        "xdg/awesome/theme.lua".source = ./theme.lua;
        "xdg/awesome/wallpaper.jpg".source = ./sebastian-svenson-d2w-_1LJioQ-unsplash.jpg;
        "xdg/gtk-3.0/settings.ini".text = ''
          [Settings]
          gtk-application-prefer-dark-theme=1
          gtk-cursor-theme-name=Adwaita
          gtk-key-theme-name=Emacs
          gtk-theme-name=Adwaita
        '';
      };
      variables = {
        XCURSOR_THEME = "Adwaita";
        XCURSOR_PATH = mkForce [ "${pkgs.gnome.adwaita-icon-theme}/share/icons" ];
      };
      systemPackages = with pkgs; [
        brightnessctl
        pulseaudio
        xclip
        xsel
      ];
    };

    services.xserver = {
      enable = true;
      layout = "us";
      xkbOptions = "ctrl:nocaps";
      displayManager.sessionCommands = ''
        ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
          Xcursor.theme: Adwaita
        EOF
      '';
      displayManager = {
        defaultSession = "none+awesome";
        autoLogin = { enable = true; user = "jared"; };
      };
      deviceSection = ''
        Option "TearFree" "true"
      '';
      windowManager.awesome.enable = true;
      libinput = mkIf cfg.laptop {
        enable = true;
        touchpad = {
          accelProfile = "flat";
          tapping = true;
          naturalScrolling = true;
        };
      };
    };

    programs.xss-lock = {
      enable = true;
      extraOptions = [ "-n" "${pkgs.xsecurelock}/libexec/xsecurelock/dimmer" "-l" ];
      lockerCommand = ''
        XSECURELOCK_AUTH_BACKGROUND_COLOR="#1a1a1a" XSECURELOCK_AUTH_FOREGROUND_COLOR="#e0e0e0" XSECURELOCK_AUTH_WARNING_COLOR="#ff929f" XSECURELOCK_DIM_COLOR="#1a1a1a" XSECURELOCK_FONT="DejaVu Sans Mono:size=14" ${pkgs.xsecurelock}/bin/xsecurelock
      '';
    };
  };

}


