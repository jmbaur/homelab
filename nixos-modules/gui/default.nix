{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;

  swaySessionTarget = "sway-session.target";
in
{
  options.custom.gui = with lib; {
    enable = mkEnableOption "GUI config";

    displays = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          match = mkOption {
            type = types.str;
            default = name;
            description = mdDoc ''
              Shikane-compatible (shikane(5)) match statements.
            '';
          };
          scale = mkOption {
            type = types.float;
            default = 1.0;
          };
          isInternal = mkEnableOption "internal display";
        };
      }));
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.pulseaudio.enable = lib.mkForce false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    fonts = {
      packages = [ pkgs.noto-fonts pkgs.jetbrains-mono ];
      fontconfig = {
        enable = true;
        defaultFonts = {
          sansSerif = [ "Noto Sans" ];
          serif = [ "Noto Serif" ];
          monospace = [ "JetBrains Mono" ];
        };
      };
    };

    nixpkgs.overlays = [
      (final: _: {
        mirror-to-x = final.writeShellScriptBin "mirror-to-x" ''
          env SDL_VIDEODRIVER=x11 \
            ${final.wf-recorder}/bin/wf-recorder \
            -c rawvideo \
            -m sdl \
            -f pipe:xwayland-mirror
        '';
        desktop-launcher = final.writeShellScriptBin "desktop-launcher" ''
          exec -a "$0" systemd-cat --identifier=sway \
            ${config.programs.sway.package}/bin/sway
        '';
        caffeine = final.writeShellScriptBin "caffeine" ''
          stop() { systemctl restart --user idle.service; }
          trap stop EXIT SIGINT
          systemctl stop --user idle.service
          echo "Press CTRL-C to restart auto-sleep"
          sleep infinity
        '';
      })
    ];

    environment.systemPackages = with pkgs; [
      alacritty
      brightnessctl
      caffeine
      chromium-wayland
      cliphist
      desktop-launcher
      firefox
      glib
      gnome-themes-extra
      gobar
      grim
      hyprpicker
      imv
      libnotify
      mako
      mirror-to-x
      mpv
      pamixer
      pulseaudio
      pulsemixer
      qt5.qtwayland
      rofi-wayland
      shikane
      shotman
      slurp
      sway-assign-cgroups
      swaybg
      swayidle
      swaylock
      wev
      wf-recorder
      wl-clipboard
      wl-screenrec
      wlr-randr
      xdg-utils
    ];

    # ensure the plugdev group exists for udev rules for qmk
    users.groups.plugdev = { };
    services.udev.packages = [
      pkgs.yubikey-personalization
      pkgs.qmk-udev-rules
      pkgs.teensy-udev-rules
    ];

    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "teensy-udev-rules" ];

    location.provider = "geoclue2";
    programs.gnupg.agent.enable = true;
    programs.ssh.startAgent = true;
    programs.wshowkeys.enable = true;
    services.automatic-timezoned.enable = lib.mkDefault true;
    services.dbus.enable = true;
    services.pcscd.enable = true;
    services.power-profiles-daemon.enable = true;
    services.printing.enable = true;
    services.udisks2.enable = true;
    services.upower.enable = true;
    xdg.portal.enable = true;
    xdg.portal.wlr.enable = true;

    services.avahi.enable = true;

    services.greetd = {
      enable = true;
      vt = 7;
      settings.default_session.command = "${pkgs.greetd.greetd}/bin/agreety --cmd desktop-launcher";
    };

    programs.sway = {
      enable = true;
      wrapperFeatures.base = true;
      wrapperFeatures.gtk = true;
      # vulkan renderer support
      # export WLR_RENDERER=vulkan
      # export VK_LAYER_PATH=${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d
      extraSessionCommands = ''
        # SDL:
        export SDL_VIDEODRIVER=wayland
        # QT (needs qt5.qtwayland in systemPackages):
        export QT_QPA_PLATFORM=wayland-egl
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
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

    systemd.user.services.display-manager = {
      inherit (config.custom.laptop) enable;
      description = "laptop display manager";
      after = [ swaySessionTarget ];
      partOf = [ swaySessionTarget ];
      path = [ pkgs.bash ]; # needs a shell to run [[profile.exec]] statements
      environment.SHIKANE_LOG = "info";
      unitConfig.ConditionPathExists = "%h/.config/shikane/config.toml";
      serviceConfig.ExecStart = "${pkgs.shikane}/bin/shikane";
      wantedBy = [ swaySessionTarget ];
    };

    systemd.user.services.yubikey-touch-detector = {
      description = "yubikey touch detector";
      after = [ swaySessionTarget ];
      partOf = [ swaySessionTarget ];
      serviceConfig.ExecStart = "${lib.getExe pkgs.yubikey-touch-detector} --libnotify";
      wantedBy = [ swaySessionTarget ];
    };

    systemd.user.services.clipboard-manager = {
      description = "clipboard manager";
      documentation = [ "https://github.com/sentriz/cliphist" ];
      after = [ swaySessionTarget ];
      partOf = [ swaySessionTarget ];
      path = [ pkgs.wl-clipboard ];
      serviceConfig = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe pkgs.cliphist} store";
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
        ExecStart = "${pkgs.gammastep}/bin/gammastep -l ${config.location.provider}";
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
      path = with pkgs; [ bash ]; # needs a shell in path
      unitConfig.ConditionPathExists = "%h/.config/swayidle/config";
      serviceConfig.ExecStart = "${lib.getExe pkgs.swayidle} -w";
    };
  };
}
