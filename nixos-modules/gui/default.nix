{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
  guiData = import ./data.nix;
in
with lib;
{
  options.custom.gui.enable = mkEnableOption "GUI config";
  config = mkIf cfg.enable {
    boot.kernelParams = [ "systemd.show_status=auto" ];

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
    services.automatic-timezoned.enable = lib.mkDefault true;

    nixpkgs.overlays = [
      (_: prev: {
        desktop-launcher = prev.writeShellScriptBin "desktop-launcher" ''
          exec -a "$0" systemd-cat --identifier=river river
        '';
      })
    ];

    environment.systemPackages = with pkgs; [
      alacritty
      bemenu
      brightnessctl
      chromium
      clipman
      desktop-launcher
      ffmpeg-full
      firefox
      fnott-dbus
      foot
      fuzzel
      gnome-themes-extra
      grim
      imv
      labwc
      libnotify
      mirror-to-x
      mpv
      pulseaudio
      pulsemixer
      qt5.qtwayland
      river
      slurp
      sway-contrib.grimshot
      swaybg
      swayidle
      swaylock
      v4l-show
      v4l-utils
      wev
      wezterm
      wf-recorder
      wl-clipboard
      wlr-randr
      xdg-utils
      yambar
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
    environment.variables.BEMENU_OPTS = escapeShellArgs [
      "--ignorecase"
      "--fn=${guiData.font}"
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
      wrapperFeatures.base = true;
      wrapperFeatures.gtk = true;
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

    systemd.user.services.statusbar = {
      description = "desktop status bar";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.yambar}/bin/yambar";
      wantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.wallpaper = {
      description = "desktop wallpaper daemon";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.swaybg}/bin/swaybg --color='#222222' --mode=solid_color";
      wantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.yubikey-touch-detector = {
      description = "yubikey touch detector";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
      wantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.clipboard-manager = {
      description = "clipboard manager";
      documentation = [ "https://github.com/yory8/clipman" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      path = [ pkgs.wl-clipboard ];
      serviceConfig.ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text/plain --watch ${pkgs.clipman}/bin/clipman store";
      wantedBy = [ "graphical-session.target" ];
    };

    systemd.user.sockets.wob = {
      socketConfig = {
        ListenFIFO = "%t/wob.sock";
        SocketMode = "0600";
      };
      wantedBy = [ "sockets.target" ];
    };

    systemd.user.services.wob = {
      description = "overlay bar";
      documentation = [ "https://github.com/francma/wob" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      serviceConfig = {
        StandardInput = "socket";
        ExecStart = "${pkgs.wob}/bin/wob";
      };
      wantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.gamma = {
      description = "gamma adjuster";
      documentation = [ "https://gitlab.com/chinstrap/gammastep" ];
      wants = [ "geoclue-agent.service" ];
      after = [ "graphical-session.target" "geoclue-agent.service" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.gammastep}/bin/gammastep -l geoclue2";
        Restart = "always";
        RestartSec = 5;
      };
      wantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.idle = {
      description = "idle management daemon";
      documentation = [ "https://github.com/swaywm/swayidle" ];
      partOf = [ "graphical-session.target" ];
      path = with pkgs; [
        bash # needs a shell in path
        swayidle
        swaylock
        sway
        (writeShellScriptBin "conditional-suspend" (lib.optionalString config.custom.laptop.enable ''
          if [[ "$(cat /sys/class/power_supply/AC/online)" -ne 1 ]]; then
            echo "laptop is not on AC, suspending"
            ${pkgs.systemd}/bin/systemctl suspend
          else
            echo "laptop is on AC, not suspending"
          fi
        ''))
      ];
      wantedBy = [ "graphical-session.target" ];
      script =
        let
          lockCmd = "swaylock ${lib.escapeShellArgs [ "--daemonize" "--indicator-caps-lock" "--show-keyboard-layout" "--color" "222222" ]}";
        in
        ''
          swayidle -w \
            timeout 300 '${lockCmd}' \
            timeout 600 'swaymsg "output * dpms off"' \
              resume 'swaymsg "output * dpms on"' \
            timeout 900 'conditional-suspend' \
            before-sleep '${lockCmd}' \
            lock '${lockCmd}' \
            after-resume 'swaymsg "output * dpms on"'
        '';
    };
  };
}
