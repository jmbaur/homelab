{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options = {
    custom.gui.enable = lib.mkEnableOption "Enable gui config";
    custom.gui.desktop = lib.mkEnableOption "Enable desktop gui config";
  };
  config = lib.mkIf cfg.enable {
    hardware.pulseaudio.enable = !config.custom.sound.enable;
    hardware.i2c.enable = cfg.desktop;

    security.polkit.enable = true;

    location.provider = "geoclue2";

    programs.adb.enable = true;
    programs.dconf.enable = true;
    programs.seahorse.enable = true;
    programs.ssh.startAgent = true;

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
        brightnessctl
        cage
        ffmpeg-full
        foot
        grim
        imv
        kitty
        libnotify
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
    programs.wshowkeys.enable = true;

    console = {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-v32n.psf.gz";
    };

    services.greetd = {
      enable = true;
      vt = 7;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
        };
      };
    };
    services.avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        workstation = true;
        addresses = true;
      };
    };
    services.gnome.gnome-keyring.enable = true;
    services.dbus.packages = [ pkgs.gcr ];
    services.pcscd.enable = false;
    services.printing.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
  };
}
