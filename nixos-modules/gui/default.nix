{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
  swaySessionTarget = "sway-session.target";
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
    fonts.packages = [ pkgs.jetbrains-mono ];

    location.provider = "geoclue2";
    services.automatic-timezoned.enable = lib.mkDefault true;

    nixpkgs.overlays = [
      (_: prev: {
        desktop-launcher = prev.writeShellScriptBin "desktop-launcher" ''
          exec -a "$0" systemd-cat --identifier=sway ${config.programs.sway.package}/bin/sway
        '';
        caffeine = prev.writeShellScriptBin "caffeine" ''
          stop() { systemctl restart --user idle.service; }
          trap stop EXIT SIGINT
          systemctl stop --user idle.service
          sleep infinity
        '';
      })
    ];

    qt.enable = true;

    environment.systemPackages = with pkgs; [
      alacritty
      bemenu
      brightnessctl
      caffeine
      chromium-wayland
      clipman
      desktop-launcher
      ffmpeg-full
      firefox
      foot
      glib
      gnome-themes-extra
      gobar
      grim
      imv
      kitty
      libnotify
      mako
      mirror-to-x
      mpv
      pamixer
      pulseaudio
      pulsemixer
      qt5.qtwayland
      shikane
      shotman
      slurp
      swaybg
      swayidle
      swaylock
      vulkan-tools
      wev
      wezterm
      wf-recorder
      wl-clipboard
      wl-color-picker
      wl-screenrec
      wlr-randr
      xdg-utils
      zathura
    ];

    services.dbus.enable = true;
    xdg.portal.enable = true;

    programs.ssh.startAgent = true;
    programs.gnupg.agent.enable = true;

    # ensure the plugdev group exists for udev rules for qmk
    users.groups.plugdev = { };
    services.udev.packages = [
      pkgs.yubikey-personalization
      pkgs.qmk-udev-rules
      pkgs.teensy-udev-rules
    ];

    services.pcscd.enable = true;
    services.power-profiles-daemon.enable = true;
    services.printing.enable = true;
    services.upower.enable = true;
    services.udisks2.enable = true;
    services.avahi.enable = true;

    services.resolved.extraConfig = ''
      MulticastDNS=no
    '';

    services.greetd = {
      enable = true;
      vt = 7;
      settings.default_session.command = "${pkgs.greetd.greetd}/bin/agreety --cmd desktop-launcher";
    };

    programs.wshowkeys.enable = true;

    xdg.portal.wlr.enable = true;

    programs.sway = {
      enable = true;
      wrapperFeatures.base = true;
      wrapperFeatures.gtk = true;
      extraSessionCommands = ''
        # vulkan renderer support
        # export WLR_RENDERER=vulkan
        # export VK_LAYER_PATH=${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d
        # SDL:
        export SDL_VIDEODRIVER=wayland
        # QT (needs qt5.qtwayland in systemPackages):
        export QT_QPA_PLATFORM=wayland-egl
        # Fix for some Java AWT applications (e.g. Android Studio), use this if
        # they aren't displayed properly:
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
    };

    systemd.user.targets.sway-session = {
      description = "sway compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    systemd.user.services.statusbar = {
      enable = false;
      description = "desktop status bar";
      after = [ swaySessionTarget ];
      partOf = [ swaySessionTarget ];
      serviceConfig.ExecStart = "${pkgs.yambar}/bin/yambar";
      wantedBy = [ swaySessionTarget ];
    };

    systemd.user.services.yubikey-touch-detector = {
      description = "yubikey touch detector";
      after = [ swaySessionTarget ];
      partOf = [ swaySessionTarget ];
      serviceConfig.ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
      wantedBy = [ swaySessionTarget ];
    };

    systemd.user.services.clipboard-manager = {
      description = "clipboard manager";
      documentation = [ "https://github.com/yory8/clipman" ];
      after = [ swaySessionTarget ];
      partOf = [ swaySessionTarget ];
      path = [ pkgs.wl-clipboard ];
      serviceConfig = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text/plain --watch ${pkgs.clipman}/bin/clipman store";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        KillMode = "mixed";
      };
      wantedBy = [ swaySessionTarget ];
    };

    systemd.user.services.gamma = {
      description = "gamma adjuster";
      documentation = [ "https://gitlab.com/chinstrap/gammastep" ];
      wants = [ "geoclue-agent.service" ];
      after = [ swaySessionTarget "geoclue-agent.service" ];
      partOf = [ swaySessionTarget ];
      serviceConfig = {
        ExecStart = "${pkgs.gammastep}/bin/gammastep -l geoclue2";
        Restart = "always";
        RestartSec = 5;
      };
      wantedBy = [ swaySessionTarget ];
    };

    systemd.user.services.idle = {
      description = "idle management daemon";
      documentation = [ "https://github.com/swaywm/swayidle" ];
      partOf = [ swaySessionTarget ];
      after = [ swaySessionTarget ];
      wantedBy = [ swaySessionTarget ];
      path = with pkgs; [
        bash # needs a shell in path
        chayang
        swayidle
        swaylock
        sway
        (writeShellScriptBin "lock" ''
          if chayang; then
            swaylock ${lib.escapeShellArgs [ "--daemonize" "--indicator-caps-lock" "--show-keyboard-layout" "--color" "000000" ]}
          fi
        '')
        (writeShellScriptBin "conditional-suspend" (lib.optionalString config.custom.laptop.enable ''
          if [[ "$(cat /sys/class/power_supply/AC/online)" -ne 1 ]]; then
            echo "laptop is not on AC, suspending"
            ${pkgs.systemd}/bin/systemctl suspend
          else
            echo "laptop is on AC, not suspending"
          fi
        ''))
      ];
      script = ''
        swayidle -w \
          timeout 300 'lock' \
          timeout 600 'swaymsg "output * dpms off"' \
            resume 'swaymsg "output * dpms on"' \
          timeout 900 'conditional-suspend' \
          before-sleep 'lock' \
          lock 'lock' \
          after-resume 'swaymsg "output * dpms on"'
      '';
    };
  };
}
