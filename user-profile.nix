{ config, pkgs, ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "35a24648d155843a4d162de98c17b1afd5db51e4";
    ref = "release-21.05";
  };
in {
  imports = [
    (import "${home-manager}/nixos")
    ./programs/alacritty.nix
    ./programs/kitty.nix
    ./programs/autorandr.nix
    ./programs/neovim.nix
    ./programs/zsh.nix
    ./programs/tmux.nix
    ./programs/git.nix
    ./programs/vscode.nix
    ./programs/obs.nix
    ./programs/psql.nix
    ./programs/podman.nix
    ./programs/i3.nix
    ./programs/i3status.nix
    ./programs/rofi.nix
    ./programs/dunst.nix
    ./programs/email.nix
  ];

  users.users.jared = {
    isNormalUser = true;
    home = "/home/jared";
    description = "Jared Baur";
    extraGroups = [ "wheel" "networkmanager" "video" "wireshark" ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;

  home-manager.users.jared = {
    manual.html.enable = true;
    home.sessionVariables = { EDITOR = "vim"; };
    home.packages = with pkgs; [
      curl
      wget
      jq
      htop
      ripgrep
      tmux
      gh
      fd
      ffmpeg-full
      sshping
      tig
      w3m
      xsel
      xclip
      pulsemixer
      glib
      neofetch
      nixfmt
      speedtest-cli
      tree
      pstree
      skopeo
      buildah
      podman-compose

      # GUI
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

    xresources.properties = {
      "Xcursor.theme" = "Adwaita";
      "Xcursor.size" = 16;
      "XTerm.termName" = "xterm-256color";
      "XTerm.vt100.utf8" = true;
      "XTerm.vt100.selectToClipboard" = true;
      "XTerm.vt100.reverseVideo" = true;
      "XTerm.vt100.faceName" = "Hack:size=14:antialias=true";
    };

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
          "text/html" = [ "firefox.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
          "x-scheme-handler/about" = [ "firefox.desktop" ];
          "x-scheme-handler/unknown" = [ "firefox.desktop" ];
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
  };
}
