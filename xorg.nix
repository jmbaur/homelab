{ config, pkgs, ... }: {

  programs.dconf.enable = true;

  #systemd.user = {
  #  timers.gtk-theme-switcher = {
  #    wantedBy = [ "timers.target" ];
  #    partOf = [ "gtk-theme-switcher" ];
  #    timerConfig.OnCalendar = "*-*-* 06,19:30:00";
  #  };
  #  services.gtk-theme-switcher = {
  #    serviceConfig.Type = "oneshot";
  #    script = ''
  #      #!${pkgs.stdenv.shell}
  #      whoami && id
  #    '';
  #  };
  #};

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
    displayManager.sessionCommands = ''
      xsetroot -solid '#2E3436'
    '';
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
      ];
    };
  };
}
