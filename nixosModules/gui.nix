{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
with lib;
{
  options.custom.gui.enable = mkEnableOption "GUI config";
  config = mkIf cfg.enable {
    environment.enableAllTerminfo = true;

    hardware.pulseaudio.enable = mkForce false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    fonts.fontconfig.enable = true;
    fonts.fonts = [ pkgs.jetbrains-mono ];

    location.provider = "geoclue2";

    nixpkgs.overlays = [
      (_: prev: {
        sway-launcher = prev.writeShellScriptBin "sway-launcher" ''
          exec -a "$0" systemd-cat --identifier=sway sway
        '';
      })
    ];
    environment.systemPackages = with pkgs; [
      ffmpeg-full
      libnotify
      pulsemixer
      sway-launcher
      wl-clipboard
      xdg-utils
      zathura
    ];

    services.dbus.enable = true;
    xdg.portal.enable = true;

    programs.ssh.startAgent = true;

    programs.firejail = {
      enable = true;
      wrappedBinaries = {
        chromium = {
          executable = "${lib.getBin pkgs.chromium-wayland}/bin/chromium";
          profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
          desktop = "${pkgs.chromium-wayland}/share/applications/chromium-browser.desktop";
          extraArgs = [
            "--ignore=private-dev"
            "--dbus-user.talk=org.freedesktop.Notifications"
          ];
        };
        firefox = {
          executable = "${lib.getBin pkgs.firefox}/bin/firefox";
          profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
          desktop = "${pkgs.firefox}/share/applications/firefox.desktop";
          extraArgs = [
            "--ignore=private-dev"
            "--dbus-user.talk=org.freedesktop.Notifications"
          ];
        };
        spotify = {
          executable = "${lib.getBin pkgs.spotify}/bin/spotify";
          profile = "${pkgs.firejail}/etc/firejail/spotify.profile";
          desktop = "${pkgs.spotify}/share/applications/spotify.desktop";
        };
      };
    };

    services.avahi.enable = true;
    services.pcscd.enable = true;
    services.power-profiles-daemon.enable = true;
    services.printing.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization pkgs.teensy-udev-rules ];
    services.upower.enable = true;
    services.udisks2.enable = true;

    services.greetd = {
      enable = true;
      vt = 7;
      settings.default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --cmd sway-launcher";
    };
    programs.wshowkeys.enable = true;
    environment.variables.BEMENU_OPTS = escapeShellArgs [
      "--ignorecase"
      "--fn=JetBrains Mono"
      "--line-height=30"
    ];

    xdg.portal.wlr.enable = true;

    boot = {
      extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      kernelModules = [ "v4l2loopback" ];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1 card_label=VirtualVideoDevice
      '';
    };

    programs.sway = {
      enable = true;
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
      extraPackages = with pkgs; [
        bemenu
        brightnessctl
        clipman
        gnome-themes-extra
        grim
        imv
        mirror-to-x
        mpv
        qt5.qtwayland
        slurp
        v4l-show
        v4l-utils
        wev
        wf-recorder
        wlr-randr
      ];
      extraSessionCommands = ''
        # vulkan renderer support
        # export WLR_RENDERER=vulkan
        # export VK_LAYER_PATH=${pkgs.vulkan-validation-layers}/result/share/vulkan/explicit_layer.d
        # SDL:
        export SDL_VIDEODRIVER=wayland
        # QT (needs qt5.qtwayland in systemPackages):
        export QT_QPA_PLATFORM=wayland-egl
        # Fix for some Java AWT applications (e.g. Android Studio), use this if
        # they aren't displayed properly:
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
    };
  };
}
