{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    alacritty
    brightnessctl
    chromium
    dunst
    element-desktop
    firefox
    firefox
    gimp
    google-chrome
    kitty
    libreoffice
    pavucontrol
    pinentry-gnome
    postman
    signal-desktop
    slack
    spotify
    wireshark
    xclip
    xsel
    zoom-us
  ];

  fonts.fonts = with pkgs; [
    dejavu_fonts
    hack-font
    inconsolata
    liberation_ttf
    liberation_ttf
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    source-code-pro
  ];

  location.provider = "geoclue2";
  services.redshift.enable = true;

  services.clipmenu.enable = true;
  services.fwupd.enable = true;
  services.printing.enable = true;

  services.syncthing = {
    enable = true;
    user = "jared";
    group = "users";
    dataDir = "/home/jared";
    configDir = "/home/jared/.config/syncthing";
    openDefaultPorts = true;
    declarative.overrideFolders = false;
    declarative.overrideDevices = true;
  };

  services.dbus.packages = [ pkgs.gcr ];

  programs.gnupg.agent.pinentryFlavor = "gnome3";

  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "ctrl:nocaps";
    deviceSection = ''
      Option "TearFree" "true"
    '';
    displayManager = {
      defaultSession = "none+i3";
      autoLogin.enable = true;
      autoLogin.user = "jared";
    };
    desktopManager.xterm.enable = true;
    windowManager.i3 = {
      enable = true;
      extraSessionCommands = ''
        xsetroot -solid "#000000"
      '';
      extraPackages = with pkgs; [
        dmenu
        i3lock
        i3status-rust
      ];
    };
  };

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  nixpkgs.config.pulseaudio = true;

  programs.xss-lock = {
    enable = true;
    lockerCommand = ''
      ${pkgs.i3lock}/bin/i3lock -c 000000
    '';
  };

}
