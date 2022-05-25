{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options = {
    custom.gui.enable = lib.mkEnableOption "Enable gui config";
  };
  config = lib.mkIf cfg.enable {
    custom.sound.enable = lib.mkDefault true;
    hardware.pulseaudio.enable = false;

    hardware.i2c.enable = true;

    security.polkit.enable = true;

    location.provider = "geoclue2";

    xdg.portal.enable = true;

    environment.variables.NIXOS_OZONE_WL = "1";

    # Make some extra kernel modules available to NixOS
    boot.extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback.out
    ];

    # Activate kernel modules (choose from built-ins and extra ones)
    boot.kernelModules = [
      # Virtual Camera
      "v4l2loopback"
      # Virtual Microphone, built-in
      "snd-aloop"
    ];

    # Set initial kernel module settings
    boot.extraModprobeConfig = ''
      # exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming
      # card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
      # https://github.com/umlaeute/v4l2loopback
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        (writeShellScriptBin "record" ''
          device=$(${v4l-utils}/bin/v4l2-ctl --list-devices | grep -C1 "Virtual Camera" | tail -n1 | xargs)
          ${wf-recorder}/bin/wf-recorder \
            --muxer=v4l2 \
            --codec=rawvideo \
            --pixel-format=yuv420p \
            --file="$device"
        '')
        alacritty
        bemenu
        brightnessctl
        cage
        clipman
        ffmpeg-full
        foot
        grim
        imv
        kitty
        libnotify
        mako
        mpv
        pulsemixer
        slurp
        swayidle
        swaylock
        v4l-utils
        wf-recorder
        wl-clipboard
        wl-color-picker
        wlr-randr
        xdg-utils
        zathura
      ];
    };

    console = {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-v32n.psf.gz";
    };

    services.greetd = {
      enable = true;
      vt = 7;
      # TODO(jared): use cage instead of sway for wlgreet when cage switches to
      # wlr-layer-shell-unstable.

      settings.default_session.command =
        let
          xdgDataDirs = "${pkgs.gnome-themes-extra}/share";
          gtkTheme = "Adwaita-dark";
        in
        "env XDG_DATA_DIRS=${xdgDataDirs} GTK_THEME=${gtkTheme} ${pkgs.cage}/bin/cage -sd -- ${pkgs.greetd.gtkgreet}/bin/gtkgreet";
    };
    environment.etc."greetd/environments".text = ''
      sway
      bash
      zsh
    '';

    programs.adb.enable = true;
    programs.dconf.enable = true;
    programs.gnupg.agent = { enable = true; pinentryFlavor = null; };
    programs.ssh.startAgent = true;
    programs.wshowkeys.enable = true;
    programs.zsh = { enable = true; interactiveShellInit = "bindkey -e"; };

    services.pcscd.enable = false;
    services.printing.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
    services.avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        workstation = true;
        addresses = true;
      };
    };

  };
}
