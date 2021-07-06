{ config, pkgs, ... }: {
  imports = [
    ../programs/i3status.nix
    ../programs/rofi.nix
    ../programs/dunst.nix
    ../programs/alacritty.nix
    ../programs/kitty.nix
    ../programs/autorandr.nix
    ../programs/vscode.nix
    ../programs/obs.nix
  ];

  programs.dconf.enable = true;
  services.autorandr.enable = true;
  services.autorandr.defaultTarget = "laptop";
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    layout = "us";
    exportConfiguration = true;
    xkbOptions = "ctrl:nocaps";
    displayManager.defaultSession = "none+i3";
    displayManager.lightdm.enable = true;
    displayManager.autoLogin.enable = true;
    displayManager.autoLogin.user = "jared";
    deviceSection = ''
      Option "TearFree" "true"
    '';

    libinput = {
      enable = true;
      touchpad.tapping = true;
      touchpad.naturalScrolling = true;
      touchpad.disableWhileTyping = true;
      touchpad.accelProfile = "flat";
    };

    windowManager.i3 = {
      enable = true;
      extraSessionCommands = ''
        xsetroot -solid '#2E3436'
        autorandr -c
      '';
      extraPackages = with pkgs; [
        i3lock
        dmenu
        rofi
        dunst
        xss-lock
        libnotify
        autorandr
        sxiv
        alacritty
        kitty
        zathura
        mpv
        screenkey
        brightnessctl
        gsettings-desktop-schemas
        gnome.adwaita-icon-theme
        i3status-rust
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    firefox
    signal-desktop
    wireshark
    qgis
    gimp
    bitwarden
    # Unfree
    spotify
    discord
    zoom-us
    slack
    brave
    google-chrome
  ];

  home-manager.users.jared = {
    home.file.".config/i3/config".text = builtins.readFile ../programs/i3config;
    xdg = {
      mime.enable = true;
      mimeApps = {
        enable = true;
        defaultApplications = {
          "image/png" = [ "sxiv.desktop" ];
          "image/jpg" = [ "sxiv.desktop" ];
          "image/jpeg" = [ "sxiv.desktop" ];
          "video/mp4" = [ "mpv.desktop" ];
          "video/webm" = [ "mpv.desktop" ];
          "application/pdf" = [ "zathura.desktop" ];
          "text/html" = [ "google-chrome.desktop" ];
          "x-scheme-handler/http" = [ "google-chrome.desktop" ];
          "x-scheme-handler/https" = [ "google-chrome.desktop" ];
          "x-scheme-handler/about" = [ "google-chrome.desktop" ];
          "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
        };
      };
      userDirs = {
        enable = true;
        createDirectories = true;
      };
    };
    services = {
      unclutter = {
        enable = true;
        extraOptions = [ "ignore-scrolling" ];
      };
      clipmenu.enable = true;
      screen-locker = {
        enable = true;
        enableDetectSleep = true;
        lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 222222";
      };
      redshift = {
        enable = true;
        dawnTime = "06:30";
        duskTime = "20:30";
        provider = "geoclue2";
      };
    };
    xresources.properties = {
      "Xcursor.theme" = "Adwaita";
      "Xcursor.size" = 16;
      "XTerm.termName" = "xterm-256color";
      "XTerm.vt100.utf8" = true;
      "XTerm.vt100.selectToClipboard" = true;
      "XTerm.vt100.reverseVideo" = true;
      "XTerm.vt100.faceName" = "Hack:size=14:antialias=true";
    };
    gtk = {
      enable = true;
      gtk3.extraConfig = {
        gtk-theme-name = "Adwaita";
        gtk-cursor-theme-name = "Adwaita";
        gtk-icon-theme-name = "Adwaita";
        gtk-key-theme-name = "Emacs";
        gtk-application-prefer-dark-theme = true;
      };
    };
  };
}
