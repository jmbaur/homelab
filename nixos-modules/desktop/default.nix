{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    getExe
    getExe'
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.custom.desktop;

  footThemes = "${config.programs.foot.package.themes}/share/foot/themes";

  footColorState = ".local/state/foot/color-theme.ini";

  # foot only picks a color theme at startup, so ship both and let the last
  # include (written by the hook below) decide which one is active.
  footColors = pkgs.runCommand "foot-colors.ini" { } ''
    cat ${footThemes}/modus-operandi ${footThemes}/modus-vivendi >$out
    printf '[main]\ninitial-color-theme=dark\ninclude=~/${footColorState}\n' >>$out
  '';

  # Also run by the gammastep hook, so a manual pick holds until the next
  # period change.
  desktopTheme = pkgs.writeShellApplication {
    name = "desktop-theme";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.dconf
      pkgs.procps
    ];
    text = ''
      theme=''${1:-toggle}
      if [ "$theme" = toggle ]; then
        case "$(dconf read /org/gnome/desktop/interface/color-scheme)" in
        *prefer-light*) theme=dark ;;
        *) theme=light ;;
        esac
      fi

      case "$theme" in
      light) gtk_theme=Adwaita color_scheme=prefer-light foot_signal=USR2 ;;
      dark) gtk_theme=Adwaita-dark color_scheme=prefer-dark foot_signal=USR1 ;;
      *)
        echo "usage: desktop-theme [light|dark|toggle]" >&2
        exit 1
        ;;
      esac

      dconf write /org/gnome/desktop/interface/color-scheme "'$color_scheme'"
      dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'"

      install -Dm0644 /dev/stdin "$HOME/${footColorState}" <<EOF
      [main]
      initial-color-theme=$theme
      EOF

      # New terminals read the file above, running ones need a signal.
      pkill --signal "$foot_signal" --exact foot || true
    '';
  };

  # gammastep hook, also run at startup with an old period of "none". Light
  # only during full daylight, so the theme tracks the color temperature.
  themeHook = getExe (
    pkgs.writeShellApplication {
      name = "gammastep-theme-hook";
      text = ''
        [ "$1" = period-changed ] || exit 0

        # Inherited from the gammastep unit, where it points into the store.
        unset XDG_CONFIG_HOME

        case "$3" in
        daytime) exec ${getExe desktopTheme} light ;;
        night | transition) exec ${getExe desktopTheme} dark ;;
        # "none" is also what gammastep reports on its way out.
        *) exit 0 ;;
        esac
      '';
    }
  );

  # gammastep resolves hooks against $XDG_CONFIG_HOME only, so hand it a store
  # directory rather than writing into the user's home.
  gammastepConfig = pkgs.linkFarm "gammastep-config" {
    "gammastep/hooks/theme" = themeHook;
  };

  swaylockThemed = pkgs.writeShellApplication {
    name = "swaylock";
    runtimeInputs = [ pkgs.dconf ];
    text = ''
      declare -a swaylock_flags
      case "$(dconf read /org/gnome/desktop/interface/color-scheme)" in
      *prefer-light*) swaylock_flags+=("--color=a3a3a3") ;;
      *) swaylock_flags+=("--color=2e2e2e") ;;
      esac

      exec ${getExe' pkgs.swaylock "swaylock"} "''${swaylock_flags[@]}" "$@"
    '';
  };

  swaylock = pkgs.symlinkJoin {
    name = "swaylock-themed";
    paths = [ pkgs.swaylock ];
    postBuild = "ln -sf ${getExe swaylockThemed} $out/bin/swaylock";
    meta.mainProgram = "swaylock";
  };

  # -theme wins over @theme in a user's config.rasi.
  rofiThemed = pkgs.writeShellApplication {
    name = "rofi";
    runtimeInputs = [ pkgs.dconf ];
    text = ''
      case "$(dconf read /org/gnome/desktop/interface/color-scheme)" in
      *prefer-light*) theme=Arc ;;
      *) theme=Arc-Dark ;;
      esac

      exec ${getExe' pkgs.rofi "rofi"} -theme "$theme" "$@"
    '';
  };

  rofi = pkgs.symlinkJoin {
    name = "rofi-themed";
    paths = [ pkgs.rofi ];
    postBuild = "ln -sf ${getExe rofiThemed} $out/bin/rofi";
    meta.mainProgram = "rofi";
  };

  sessionUnit = {
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
  };
in
{
  options.custom.desktop.enable = mkEnableOption "desktop";

  config = mkIf cfg.enable (mkMerge [
    {
      custom.normalUser.enable = true;

      services.greetd = {
        enable = true;
        settings.default_session.command = toString [
          "${getExe' config.services.greetd.package "agreety"}"
          "--cmd"
          ''"systemd-cat --identifier=sway ${getExe config.programs.sway.package}"''
        ];
      };

      programs.sway = {
        enable = true;
        extraPackages = [ ];
      };

      systemd.user.services.xdg-desktop-portal-wlr.path = [ rofi ];

      # Sway doesn't run XDG autostart entries, so use the upstream user unit
      # to create ~/Downloads, ~/Documents, etc.
      systemd.packages = [ pkgs.xdg-user-dirs ];
      systemd.user.services.xdg-user-dirs.wantedBy = [ "graphical-session-pre.target" ];

      systemd.user.services.swaybg = mkMerge [
        sessionUnit
        {
          serviceConfig.ExecStart = toString [
            (getExe pkgs.swaybg)
            "--mode"
            "tile"
            "--image"
            (pkgs.runCommand "weston-pattern.png" { } ''
              install -Dm0644 ${pkgs.weston}/share/weston/pattern.png $out
            '')
          ];
        }
      ];

      systemd.user.services.swayidle = mkMerge [
        sessionUnit
        {
          path = [
            pkgs.bash
            pkgs.wlopm
          ];
          serviceConfig.ExecStart = toString [
            (getExe pkgs.swayidle)
            "-w"
            "timeout"
            300
            "'${getExe swaylock} -f'"
            "timeout"
            600
            "'wlopm --off *'"
            "timeout"
            1800
            "'systemctl suspend'"
            "before-sleep"
            "'${getExe swaylock} -f'"
            "lock"
            "'${getExe swaylock} -f'"
          ];
        }
      ];

      # geoclue needs a working wifi lookup; set location.provider = "manual"
      # with coordinates on hosts where it cannot resolve one.
      location.provider = mkDefault "geoclue2";

      systemd.user.services.gammastep = mkMerge [
        sessionUnit
        {
          # Also means a user config.ini is ignored, the unit owns the settings.
          environment.XDG_CONFIG_HOME = "${gammastepConfig}";
          # geoclue occasionally fails to hand out a location and gammastep
          # exits, taking the theme hook with it until the next session.
          serviceConfig.Restart = "on-failure";
          serviceConfig.RestartSec = 10;
          serviceConfig.ExecStart = toString [
            (getExe pkgs.gammastep)
            "-l"
            (
              if config.location.provider == "manual" then
                "manual:lat=${toString config.location.latitude}:lon=${toString config.location.longitude}"
              else
                "geoclue2"
            )
          ];
        }
      ];

      systemd.user.services.kanshi = mkMerge [
        sessionUnit
        {
          serviceConfig.ExecStart = toString [
            (getExe pkgs.kanshi)
            "--config"
            (pkgs.writeText "kanshi.conf" ''
              profile docked {
                output eDP-1 disable
                output * enable
              }
              profile undocked {
                output * enable
              }
            '')
          ];
        }
      ];

      systemd.user.services.clipman = mkMerge [
        sessionUnit
        {
          serviceConfig.ExecStart = toString [
            (getExe' pkgs.wl-clipboard "wl-paste")
            "-t"
            "text"
            "--watch"
            (getExe pkgs.clipman)
            "store"
            "--no-persist"
          ];
        }
      ];

      programs.foot = {
        enable = true;
        settings = {
          mouse.hide-when-typing = "yes";
          # timers like pomo usually fire in the window being worked in
          desktop-notifications.inhibit-when-focused = "no";
          main = {
            font = "monospace:size=11";
            resize-by-cells = "no";
            selection-target = "both";
            include = [ "${footColors}" ];
          };
        };
      };

      # foot errors on a missing include, so seed the state file for sessions
      # that start one before gammastep has run the hook.
      systemd.user.tmpfiles.rules = [
        "f %h/${footColorState} 0644 - - - [main]\\ninitial-color-theme=dark\\n"
      ];

      environment.variables = {
        XKB_DEFAULT_MODEL = config.services.xserver.xkb.model;
        XKB_DEFAULT_OPTIONS = config.services.xserver.xkb.options;
        XKB_DEFAULT_VARIANT = config.services.xserver.xkb.variant;
        QT_QPA_PLATFORMTHEME = "gtk3"; # easy QT theme integration
      };

      fonts = {
        packages = [ pkgs.jetbrains-mono ];
        fontconfig.defaultFonts.monospace = [ "JetBrains Mono" ];
      };

      environment.systemPackages = [
        desktopTheme
        pkgs.brightnessctl
        pkgs.clipman
        pkgs.foot
        pkgs.gammastep
        pkgs.gnome-themes-extra
        pkgs.grim
        pkgs.homelab-utils.swaybar-status
        pkgs.kanshi
        pkgs.libnotify
        pkgs.mako
        pkgs.pulseaudio
        pkgs.slurp
        pkgs.swaybg
        pkgs.swayidle
        pkgs.wev
        pkgs.wf-recorder
        pkgs.wl-clipboard
        pkgs.wl-mirror
        pkgs.wlopm
        pkgs.wlr-randr
        pkgs.wmenu
        pkgs.zathura
        rofi
        swaylock
        (pkgs.symlinkJoin {
          name = "default-${pkgs.xcursor-chromeos.name}";
          paths = [ pkgs.xcursor-chromeos ];
          postBuild = ''
            ln -sf $out/share/icons/${pkgs.xcursor-chromeos.pname} $out/share/icons/default
          '';
        })
      ];

      programs.yubikey-touch-detector.enable = mkDefault true;
      security.rtkit.enable = mkDefault true;
      services.automatic-timezoned.enable = mkDefault true;
      services.fwupd.enable = mkDefault true;
      services.hardware.bolt.enable = mkDefault true;
      services.printing.enable = mkDefault true;
      services.upower.enable = mkDefault true;

      programs.dconf = {
        enable = true;
        profiles.user.databases = [
          {
            # Only the fallback, the gammastep hook writes these per-user.
            settings."org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-theme = "Adwaita";
            };
          }
        ];
      };

      programs.firefox = {
        enable = mkDefault true;

        # Allow users to override preferences set here
        preferencesStatus = "user";

        preferences = mkMerge (
          [
            {
              # Default value only looks good in GNOME
              "browser.tabs.inTitlebar" = mkIf (!config.services.desktopManager.gnome.enable) 0;
            }
          ]
          # Default is 2 for some reason, using 1 makes firefox use the
          # native portal variant.
          ++ map (opt: { "widget.use-xdg-desktop-portal.${opt}" = 1; }) [
            "file-picker"
            "mime-handler"
            "settings"
            "location"
            "open-uri"
          ]
        );
      };
    }

    # Networking defaults
    {
      custom.basicNetwork.enable = true;

      networking.networkmanager = {
        enable = mkDefault true;
        # geoclue only reads nearby access points from wpa_supplicant.
        # Without them, location lookups fall back to IP geolocation.
        wifi.backend = mkDefault "wpa_supplicant";
        # Random MAC address per network, stable across reconnects.
        wifi.macAddress = mkDefault "stable";
      };

      hardware.bluetooth.enable = true;

      # We use systemd-resolved
      services.avahi.enable = false;

      # Allows desktops to do stuff like timezone detection, display
      # modifications (brightness, redshift), etc.
      services.geoclue2.enable = true;

      # It would be uncommon for a desktop system to have an NMEA serial device,
      # plus setting this to true means that geoclue will be dependent on avahi
      # being enabled, since NMEA support in geoclue uses avahi.
      services.geoclue2.enableNmea = mkDefault false;
    }
  ]);
}
