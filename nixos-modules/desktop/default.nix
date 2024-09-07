{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.desktop;

  xcursorSize = 24;
  xcursorTheme = "DMZ-Black";
  wallpaper = pkgs.nixos-artwork.wallpapers.binary-white.kdeFilePath;

  lockCmd = "${lib.getExe pkgs.swaylock} --daemonize --show-failed-attempts --image=/etc/sway/wallpaper --scaling=fill";

  # For xwayland applications
  defaultIconTheme = pkgs.runCommand "default-icon-theme" { } ''
    mkdir -p $out/share/icons/default
    printf "[Icon Theme]\nInherits=${xcursorTheme}\n" >$out/share/icons/default/index.theme
  '';

  caffeineScript = pkgs.writeShellScriptBin "caffeine" ''
    time=''${1:-infinity}
    echo "inhibiting idle for $time"
    systemd-inhibit --what=idle --who=caffeine --why=Caffeine --mode=block sleep "$time"
  '';
in
{
  options.custom.desktop.enable = lib.mkEnableOption "desktop";

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [ "quiet" ];
    boot.consoleLogLevel = lib.mkDefault 3;

    custom.normalUser.enable = true;
    custom.basicNetwork.enable = true;

    services.graphical-desktop.enable = true;

    # Add a default browser to use
    programs.firefox = {
      enable = true;
      # Allow users to override preferences set here
      preferencesStatus = "user";
      # Default value only looks good in GNOME
      preferences."browser.tabs.inTitlebar" = lib.mkIf (
        !config.services.xserver.desktopManager.gnome.enable
      ) 0;
    };

    networking.wireless.iwd.enable = true;
    networking.networkmanager.wifi.backend = "iwd";

    # TODO(jared): Doesn't cross compile
    services.fwupd.enable = pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform;

    hardware.bluetooth.enable = true;
    security.rtkit.enable = true;
    services.pipewire.wireplumber.enable = true;

    services.automatic-timezoned.enable = lib.mkDefault true;
    services.upower.enable = lib.mkDefault true;

    # TODO(jared): Doesn't cross compile
    services.power-profiles-daemon.enable = lib.mkDefault (
      pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform
    );

    # It would be uncommon for a desktop system to have an NMEA serial device,
    # plus setting this to true means that geoclue will be dependent on avahi
    # being enabled, since NMEA support in geoclue uses avahi.
    services.geoclue2.enableNmea = lib.mkDefault false;

    # MLS is deprecated: https://github.com/NixOS/nixpkgs/issues/321121
    #
    # NOTE: This is for personal usage only (and has very low limits), be a
    # good person and get your own API key.
    services.geoclue2.geoProviderUrl =
      "https://www.googleapis.com/geolocation/v1/geolocate?key="
      + "A"
      + "I"
      + "z"
      + "a"
      + "S"
      + "y"
      + "A"
      + "_"
      + "W"
      + "j"
      + "R"
      + "8"
      + "4"
      + "L"
      + "S"
      + "r"
      + "J"
      + "r"
      + "t"
      + "R"
      + "L"
      + "a"
      + "S"
      + "I"
      + "j"
      + "G"
      + "-"
      + "Q"
      + "f"
      + "n"
      + "s"
      + "c"
      + "N"
      + "c"
      + "v"
      + "3"
      + "P"
      + "y"
      + "Y";

    services.greetd = {
      enable = true;
      settings.default_session.command = ''${lib.getExe' pkgs.greetd.greetd "agreety"} --cmd "systemd-cat --identifier=sway sway"'';
    };

    programs.sway = {
      enable = true;
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
      extraPackages = [ ];
    };

    services.dbus.packages = [ pkgs.mako ];

    environment.pathsToLink = [ "/share/wallpapers" ];
    environment.systemPackages = with pkgs; [
      alacritty
      brightnessctl
      caffeineScript
      cliphist
      defaultIconTheme
      gnome-themes-extra
      libnotify
      mako
      pamixer
      pulsemixer
      rofi-wayland
      shotman
      tinybar
      vanilla-dmz
      wl-clipboard
    ];

    system.userActivationScripts.xdg-user-dirs = lib.getExe' pkgs.xdg-user-dirs "xdg-user-dirs-update";

    # Same fonts as KDE, they're nice
    fonts.packages = [
      pkgs.noto-fonts
      pkgs.hack-font
    ];
    fonts.fontconfig.defaultFonts = {
      monospace = [
        "Hack"
        "Noto Sans Mono"
      ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };

    programs.gnupg.agent.pinentryPackage =
      # TODO(jared): Doesn't work, unknown reason.
      # pkgs.pinentry-rofi.override { rofi = pkgs.rofi-wayland; };
      pkgs.pinentry-tty;

    # Create a default wallpaper, but allow for changing it
    systemd.tmpfiles.settings."10-sway-wallpaper"."/etc/sway/wallpaper".L.argument = wallpaper;

    # Override the upstream defaults
    environment.etc."sway/config".source = lib.mkForce (
      pkgs.substituteAll {
        src = ./sway.conf.in;
        inherit xcursorSize xcursorTheme;
        xkbLayout = config.services.xserver.xkb.layout;
        xkbModel = config.services.xserver.xkb.model;
        xkbOptions = config.services.xserver.xkb.options;
        xkbVariant = config.services.xserver.xkb.variant;

        postInstall = ''
          if grep --silent \/nix\/store $target; then
            echo "The default config should be able to be copied without any"
            echo "reliance on nix store paths, since these paths may not"
            echo "always exist (e.g. after garbage collection)."
            exit 1;
          fi
        '';
      }
    );

    environment.etc."xdg/foot/foot.ini".source = (pkgs.formats.ini { }).generate "foot.ini" {
      main = {
        font = "monospace:size=12";
        selection-target = "both";
      };
      mouse.hide-when-typing = "yes";
      # From https://codeberg.org/dnkl/foot/src/branch/master/themes/modus-vivendi
      colors = {
        background = "000000";
        foreground = "ffffff";
        regular0 = "000000";
        regular1 = "ff8059";
        regular2 = "44bc44";
        regular3 = "d0bc00";
        regular4 = "2fafff";
        regular5 = "feacd0";
        regular6 = "00d3d0";
        regular7 = "bfbfbf";
        bright0 = "595959";
        bright1 = "ef8b50";
        bright2 = "70b900";
        bright3 = "c0c530";
        bright4 = "79a8ff";
        bright5 = "b6a0ff";
        bright6 = "6ae4b9";
        bright7 = "ffffff";
      };
    };

    # Looks the best with sway defaults
    environment.etc."xdg/rofi.rasi".text = ''
      configuration {
        terminal: "alacritty";
        font: "monospace 10";
      }
      @theme "Paper"
    '';

    environment.etc."xdg/alacritty/alacritty.toml".source =
      (pkgs.formats.toml { }).generate "alacritty.toml"
        {
          import = [
            (pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/anhsirk0/alacritty-themes/97e2cf7151f7eaf61d0f9d973bdd9dc74e403f52/themes/modus-vivendi-deuteranopia.toml";
              hash = "sha256-6pc12Jy+B6i8dzauEOemy1Mipo/kHhSlVvX2HX9NsVU=";
            })
          ];
          live_config_reload = false;
          mouse.hide_when_typing = true;
          selection.save_to_clipboard = true;
          terminal.osc52 = "CopyPaste";
          font.size = 12;
        };

    programs.dconf = with lib.gvariant; {
      enable = true;
      profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              cursor-size = mkInt32 xcursorSize;
              cursor-theme = xcursorTheme;
            };
          };
        }
      ];
    };

    systemd.user.services.swayidle = {
      description = "Idle manager for Wayland";
      documentation = [ "man:swayidle(1)" ];
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];

      # swayidle executes commands using "sh -c", so the PATH needs to contain
      # a shell.
      path = [ pkgs.bash ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = toString (
          lib.flatten [
            (lib.getExe pkgs.swayidle)
            "-w"
            [
              "timeout"
              "600"
              (lib.escapeShellArg "loginctl lock-session")
            ]
            [
              "timeout"
              "900"
              (lib.escapeShellArg "swaymsg output * power off")
              "resume"
              (lib.escapeShellArg "swaymsg output * power on")
            ]
            [
              "timeout"
              "1200"
              (lib.escapeShellArg "systemctl suspend")
            ]
            [
              "before-sleep"
              (lib.escapeShellArg lockCmd)
            ]
            [
              "lock"
              (lib.escapeShellArg lockCmd)
            ]
          ]
        );
      };
    };

    systemd.user.services.cliphist = {
      description = "Clipboard management daemon";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --watch ${lib.getExe pkgs.cliphist} ${
          lib.escapeShellArgs [
            "-max-dedupe-search"
            "10"
            "-max-items"
            "500"
          ]
        } store";
        Restart = "on-failure";
      };
    };

    systemd.user.services.gammastep = {
      description = "Display colour temperature adjuster";
      documentation = [ "https://gitlab.com/chinstrap/gammastep" ];
      after = [
        "graphical-session-pre.target"
        config.systemd.user.services.geoclue-agent.name
      ];
      wants = [ config.systemd.user.services.geoclue-agent.name ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = toString [
          (lib.getExe pkgs.gammastep)
          "-l"
          "geoclue2"
        ];
        RestartSec = 3;
        Restart = "on-failure";
      };
    };

    systemd.packages = [ pkgs.yubikey-touch-detector ];
    systemd.user.services.yubikey-touch-detector = {
      path = [ config.programs.gnupg.package ];
      wantedBy = [ "graphical-session.target" ];
    };
    systemd.user.services.yubikey-touch-detector.serviceConfig.ExecStart = [
      "" # clear previous ExecStart
      "${lib.getExe pkgs.yubikey-touch-detector} -libnotify"
    ];
  };
}
