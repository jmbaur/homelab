{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;

  compositor = {
    sway = {
      target = "sway-session.target";
      executable = lib.getExe config.programs.sway.package;
    };
    labwc = {
      target = "labwc-session.target";
      executable = lib.getExe' pkgs.labwc "labwc";
    };
  }.${cfg.compositor};

  gtkCss = pkgs.runCommand "gtk.css" { } ''
    ${lib.getDev pkgs.buildPackages.glib}/bin/gresource \
       extract \
       ${pkgs.gtk3}/lib/libgtk-3.so \
       "/org/gtk/libgtk/theme/Adwaita/gtk-contained${lib.optionalString (cfg.theme == "dark") "-dark"}.css" >$out
  '';

  labwcGtkTheme = pkgs.runCommand "labwc-gtk-theme" { } ''
    mkdir -p $out/share/themes/GTK/openbox-3
    ${lib.getExe pkgs.buildPackages.labwc-gtktheme} \
      --css-file ${gtkCss} \
      --outfile $out/share/themes/GTK/openbox-3/themerc
  '';
in
{
  options.custom.gui = with lib; {
    enable = mkEnableOption "GUI config";

    compositor = mkOption {
      type = types.enum [ "sway" "labwc" ];
      default = "labwc";
    };

    theme = mkOption {
      type = types.enum [ "light" "dark" ];
      default = "light";
    };

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

    security.polkit.enable = true;
    security.pam.services.waylock = { };

    hardware.opengl.enable = true;
    fonts.enableDefaultPackages = true;

    fonts = {
      packages = [ pkgs.noto-fonts pkgs.jetbrains-mono pkgs.font-awesome ];
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
          exec -a "$0" systemd-cat --identifier=${cfg.compositor} ${compositor.executable}
        '';

        caffeine = final.writeShellScriptBin "caffeine" ''
          stop() { systemctl restart --user idle.service; }
          trap stop EXIT SIGINT
          systemctl stop --user idle.service
          echo "Press CTRL-C to restart auto-sleep"
          sleep infinity
        '';

        rofi-cliphist-copy = final.writeShellScriptBin "rofi-cliphist-copy" ''
          cliphist list |
            rofi -i -p clipboard -dmenu -display-columns 2 |
            cliphist decode |
            wl-copy
        '';

        default-icon-theme = final.runCommand "default-icon-theme" { } ''
          install -D <(echo -e "[icon theme]\nInherits=Adwaita") $out/share/icons/default/index.theme
        '';
      })
    ];

    environment.sessionVariables = {
      QT_QPA_PLATFORM = "wayland-egl";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      SDL_VIDEODRIVER = "wayland";
      XCURSOR_SIZE = "32";
      XCURSOR_THEME = "Adwaita";
      XKB_DEFAULT_MODEL = config.services.xserver.xkbModel;
      XKB_DEFAULT_OPTIONS = config.services.xserver.xkbOptions;
      XKB_DEFAULT_VARIANT = config.services.xserver.xkbVariant;
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    environment.systemPackages = with pkgs; ([
      alacritty
      brightnessctl
      caffeine
      chromium-wayland
      cliphist
      default-icon-theme
      desktop-launcher
      firefox
      fnott
      fuzzel
      gnome-themes-extra
      grim
      hyprpicker
      imv
      kitty
      libnotify
      mirror-to-x
      mpv
      pamixer
      pulseaudio
      pulsemixer
      qt5.qtwayland
      rofi-cliphist-copy
      rofi-wayland
      shikane
      shotman
      slurp
      swaybg
      swayidle
      wev
      wf-recorder
      wl-clipboard
      wl-screenrec
      wlr-randr
      xdg-utils
    ] ++ (lib.optionals (cfg.compositor == "labwc") [
      labwc
      labwcGtkTheme
    ]) ++ (lib.optionals (cfg.compositor == "sway") [
      sway-assign-cgroups
      gobar
    ]));

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

    programs.dconf = {
      enable = true;
      profiles.user.databases = [{
        settings = with lib.gvariant; {
          "org/gnome/desktop/interface" = {
            gtk-theme = mkString "Default";
            cursor-theme = mkString "Default";
            cursor-size = mkInt32 32;
          };
        };
      }];
    };

    programs.gnupg.agent.enable = true;
    programs.gnupg.agent.pinentryFlavor = null;
    programs.gnupg.agent.settings.pinentry-program = "${pkgs.wayprompt}/bin/pinentry-wayprompt";
    programs.ssh.startAgent = true;
    programs.wshowkeys.enable = true;
    programs.xwayland.enable = true;

    services.automatic-timezoned.enable = lib.mkDefault true;
    services.avahi.enable = true;
    services.dbus.enable = true;
    services.pcscd.enable = true;
    services.power-profiles-daemon.enable = true;
    services.printing.enable = true;
    services.udisks2.enable = true;
    services.upower.enable = true;

    xdg.portal.enable = true;
    xdg.portal.wlr.enable = true;
    xdg.portal.config = {
      sway = { sway.default = [ "wlr" "gtk" ]; };
      labwc = { wlroots.default = [ "wlr" "gtk" ]; };
    }.${cfg.compositor};

    services.greetd = {
      enable = true;
      vt = 7;
      settings.default_session.command = "${pkgs.greetd.greetd}/bin/agreety --cmd desktop-launcher";
    };

    programs.sway = {
      enable = cfg.compositor == "sway";
      wrapperFeatures.base = true;
      wrapperFeatures.gtk = true;
    };

    systemd.user.targets.sway-session = {
      description = "sway compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    systemd.user.targets.labwc-session = {
      description = "labwc compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    systemd.user.services.background = {
      description = "desktop background";
      documentation = [ "https://github.com/swaywm/swaybg" ];
      after = [ compositor.target ];
      partOf = [ compositor.target ];
      serviceConfig.ExecStart = "${lib.getExe pkgs.swaybg} --color='#444444'";
      wantedBy = [ compositor.target ];
    };

    systemd.user.services.statusbar = {
      description = "statusbar";
      documentation = [ "https://github.com/Alexays/waybar" ];
      after = [ compositor.target ];
      partOf = [ compositor.target ];
      serviceConfig.ExecStart = toString [
        (lib.getExe pkgs.waybar)
        "--style=${./waybar-style.css}"
        "--config=${(pkgs.formats.json {}).generate "waybar.json" (import ./waybar.nix)}"
      ];
      wantedBy = [ compositor.target ];
    };

    systemd.user.services.display-manager = {
      inherit (config.custom.laptop) enable;
      description = "laptop display manager";
      after = [ compositor.target ];
      partOf = [ compositor.target ];
      path = [ pkgs.bash ]; # needs a shell to run [[profile.exec]] statements
      environment.SHIKANE_LOG = "info";
      unitConfig.ConditionPathExists = "%h/.config/shikane/config.toml";
      serviceConfig.ExecStart = "${pkgs.shikane}/bin/shikane";
      wantedBy = [ compositor.target ];
    };

    systemd.user.services.yubikey-touch-detector = {
      description = "yubikey touch detector";
      after = [ compositor.target ];
      partOf = [ compositor.target ];
      serviceConfig.ExecStart = "${lib.getExe pkgs.yubikey-touch-detector} --libnotify";
      wantedBy = [ compositor.target ];
    };

    systemd.user.services.clipboard = {
      description = "clipboard";
      documentation = [ "https://github.com/sentriz/cliphist" ];
      after = [ compositor.target ];
      partOf = [ compositor.target ];
      path = [ pkgs.wl-clipboard ];
      serviceConfig = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe pkgs.cliphist} store";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        KillMode = "mixed";
      };
      wantedBy = [ compositor.target ];
    };

    systemd.user.services.gamma = {
      description = "gamma adjuster";
      documentation = [ "https://gitlab.com/chinstrap/gammastep" ];
      wants = [ "geoclue-agent.service" ];
      after = [ compositor.target "geoclue-agent.service" ];
      partOf = [ compositor.target ];
      serviceConfig = {
        ExecStart = "${pkgs.gammastep}/bin/gammastep -l ${config.location.provider}";
        Restart = "always";
        RestartSec = 5;
      };
      wantedBy = [ compositor.target ];
    };

    systemd.user.services.idle = {
      description = "idle management daemon";
      documentation = [ "https://github.com/swaywm/swayidle" ];
      partOf = [ compositor.target ];
      after = [ compositor.target ];
      wantedBy = [ compositor.target ];
      path = with pkgs; [ bash ]; # needs a shell in path
      unitConfig.ConditionPathExists = "%h/.config/swayidle/config";
      serviceConfig.ExecStart = "${lib.getExe pkgs.swayidle} -w";
    };
  };
}
