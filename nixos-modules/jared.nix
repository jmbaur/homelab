{ lib, config, pkgs, ... }:
let
  cfg = config.custom.users.jared;
  guiData = import ./gui/data.nix;
  colors = guiData.colors.modus-vivendi;
  configFiles = pkgs.linkFarm "jared-config-files" [
    {
      name = "share/themes/GTK/openbox-3/themerc";
      path = ./home-manager/labwc-gtk-themerc;
    }
    {
      name = "etc/xdg/labwc/autostart";
      path = pkgs.writeText "labwc-autostart" ''
        systemctl --user start graphical-session.target
      '';
    }
    { name = "etc/xdg/labwc/rc.xml"; path = ./home-manager/labwc-rc.xml; }
    { name = "etc/xdg/labwc/menu.xml"; path = ./home-manager/labwc-menu.xml; }
    {
      name = "etc/xdg/yambar/config.yml";
      path = (pkgs.formats.yaml { }).generate "yambar.yml" {
        bar = {
          font = "${guiData.font}:size=14";
          location = "top";
          height = 30;
          background = "353535ff";
          foreground = "ffffffff";
          left = [{
            foreign-toplevel.content.map.conditions = {
              "~activated".empty = { };
              activated = [{ string = { text = "{app-id}: {title}"; max = 50; }; }];
            };
          }];
          center = [{
            clock = {
              time-format = "%H:%M %Z";
              content.string.text = "{date} {time}";
            };
          }];
          right = [{
            battery = {
              name = "BAT0";
              poll-interval = 30;
              content.string.text = "BAT: {capacity}% {estimate}";
            };
          }];
        };
      };
    }
    {
      name = "etc/xdg/fuzzel/fuzzel.ini";
      path = (pkgs.formats.ini { }).generate "fuzzel.ini" {
        main = {
          font = "${guiData.font}:size=10";
          icon-theme = guiData.gtkIconTheme;
          terminal = "wezterm start";
        };
        key-bindings = {
          cancel = "Control+bracketleft Escape";
          delete-prev = "BackSpace Control+h";
          delete-prev-word = "Mod1+BackSpace Control+BackSpace Control+w";
          delete-next = "Control+d";
        };
      };
    }
    {
      name = "etc/xdg/fnott/fnott.ini";
      path = (pkgs.formats.ini { }).generate "fnott.ini" {
        main = {
          icon-theme = guiData.gtkIconTheme;
          anchor = "top-right";
          title-font = "${guiData.font}:size=10";
          summary-font = "${guiData.font}:size=10";
          body-font = "${guiData.font}:size=10";
        };
      };
    }
    {
      name = "etc/xdg/mimeapps.list";
      path = (pkgs.formats.ini { }).generate "mimeapps.list" {
        "Added Associations" = { };
        "Removed Associations" = { };
        "Default Applications" = {
          "application/pdf" = "org.pwmt.zathura.desktop";
          "audio/*" = "mpv.desktop";
          "image/jpeg" = "imv.desktop";
          "image/png" = "imv.desktop";
          "text/*" = "nvim.desktop";
          "video/*" = "mpv.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
        };
      };
    }
    {
      name = "etc/xdg/gobar/gobar.yaml";
      path = (pkgs.formats.yaml { }).generate "gobar.yaml" {
        colorVariant = "dark";
        modules = [{ module = "network"; pattern = "(en|eth|wlp|wlan|wg)+"; }] ++
          (lib.optional config.custom.laptop.enable { module = "battery"; }) ++
          [
            { module = "memory"; }
            { module = "datetime"; timezones = [ "Local" "UTC" ]; }
          ];
      };
    }
    {
      name = "etc/xdg/alacritty/alacritty.yml";
      path = (pkgs.formats.yaml { }).generate "alacritty.yml" {
        live_config_reload = false;
        mouse.hide_when_typing = true;
        selection.save_to_clipboard = true;
        font = { normal.family = guiData.font; size = 16; };
        colors = lib.mapAttrsRecursive (_: color: "#${color}") {
          primary = {
            foreground = colors.foreground;
            background = colors.background;
          };
          normal = {
            black = colors.regular0;
            red = colors.regular1;
            green = colors.regular2;
            yellow = colors.regular3;
            blue = colors.regular4;
            magenta = colors.regular5;
            cyan = colors.regular6;
            white = colors.regular7;
          };
          bright = {
            black = colors.bright0;
            red = colors.bright1;
            green = colors.bright2;
            yellow = colors.bright3;
            blue = colors.bright4;
            magenta = colors.bright5;
            cyan = colors.bright6;
            white = colors.bright7;
          };
        };
      };
    }
    {
      name = "etc/xdg/foot/foot.ini";
      path = (pkgs.formats.ini { }).generate "foot.ini" {
        main = {
          font = "${guiData.font}:size=10";
          selection-target = "clipboard";
          notify-focus-inhibit = "no";
        };
        bell = {
          urgent = "yes";
          command-focused = "yes";
        };
        mouse.hide-when-typing = "yes";
        colors = { alpha = 1.0; } // colors;
      };
    }
    {
      name = "etc/xdg/wezterm/wezterm.lua";
      path = ./home-manager/wezterm.lua;
    }
    {
      name = "etc/xdg/wezterm/colors/modus-vivendi.toml";
      path = (pkgs.formats.toml { }).generate "modus-vivendi.toml" {
        colors = {
          background = "#${colors.background}";
          foreground = "#${colors.foreground}";
          cursor_border = "#${colors.foreground}";
          selection_bg = "rgba(40% 40% 40% 40%)";
          selection_fg = "none";
          ansi = map (color: "#${color}") [ colors.regular0 colors.regular1 colors.regular2 colors.regular3 colors.regular4 colors.regular5 colors.regular6 colors.regular7 ];
          brights = map (color: "#${color}") [ colors.bright0 colors.bright1 colors.bright2 colors.bright3 colors.bright4 colors.bright5 colors.bright6 colors.bright7 ];
        };
        metadata.name = "modus-vivendi";
      };
    }
  ];
in
{
  options.custom.users.jared = {
    enable = lib.mkEnableOption "jared";
    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };
  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;
    users.users.jared = {
      inherit (cfg) passwordFile;
      isNormalUser = true;
      description = "Jared Baur";
      shell = pkgs.fish;
      openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
      packages = with pkgs; [
        (weechat.override { configure = { ... }: { scripts = with pkgs.weechatScripts; [ weechat-matrix ]; }; })
        age-plugin-yubikey
        configFiles
        gmni
        iperf3
        librespeed-cli
        nmap
        nvme-cli
        picocom
        pwgen
        rage
        rtorrent
        sl
        smartmontools
        stow
        tailscale
        tcpdump
        tree
        unzip
        usbutils
        w3m
        wireguard-tools
        zip
      ];
      extraGroups = [ "dialout" "wheel" "plugdev" ]
        ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
        ++ (lib.optional config.programs.adb.enable "adbusers")
        ++ (lib.optional config.programs.flashrom.enable "plugdev")
        ++ (lib.optional config.programs.wireshark.enable "wireshark")
        ++ (lib.optional config.virtualisation.docker.enable "docker")
      ;
    };

    home-manager.users.jared = { nixosConfig, config, pkgs, ... }: {
      programs.git = {
        userEmail = "jaredbaur@fastmail.com";
        userName = nixosConfig.users.users.jared.description;
        extraConfig = {
          commit.gpgSign = true;
          gpg.format = "ssh";
          gpg.ssh.defaultKeyCommand = "ssh-add -L";
          gpg.ssh.allowedSignersFile = toString (pkgs.writeText "allowedSignersFile" ''
            ${config.programs.git.userEmail} sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
            ${config.programs.git.userEmail} sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
          '');
          url."git@github.com:".pushInsteadOf = "https://github.com/";
          user.signingKey = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=";
        };
      };
      programs.gpg.publicKeys = [
        {
          trust = 5;
          source = pkgs.fetchurl {
            url = "https://keybase.io/jaredbaur/pgp_keys.asc";
            sha256 = "0rw02akfvdrpdrznhaxsy8105ng5r8xb5mlmjwh9msf4brnbwrj7";
          };
        }
      ];
      programs.ssh = {
        enable = true;
        matchBlocks = {
          "*.home.arpa".forwardAgent = true;
        };
      };
    };
  };
}
