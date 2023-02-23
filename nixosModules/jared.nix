{ lib, config, pkgs, ... }:
let
  cfg = config.custom.users.jared;
  data = import ./gui/data.nix;
  colors = data.colors.modus-vivendi;
  configFiles = pkgs.linkFarm "jared-config-files" [
    {
      name = "etc/xdg/gobar/gobar.yaml";
      path = (pkgs.formats.yaml { }).generate "gobar.yaml" {
        colorVariant = "dark";
        modules = (lib.optional config.custom.laptop.enable { module = "battery"; })
          ++ [
          { module = "network"; pattern = "(en|eth|wlp|wlan|wg)+"; }
          { module = "memory"; }
          { module = "datetime"; timezones = [ "Local" "UTC" ]; }
        ];
      };
    }
    {
      name = "etc/xdg/gtk-4.0/settings.ini";
      path = (pkgs.formats.ini { }).generate "settings.ini" {
        Settings = {
          gtk-icon-theme-name = data.gtkIconTheme;
          gtk-theme-name = data.gtkTheme;
        };
      };
    }
    {
      name = "etc/xdg/gtk-3.0/settings.ini";
      path = (pkgs.formats.ini { }).generate "settings.ini" {
        Settings = {
          gtk-icon-theme-name = data.gtkIconTheme;
          gtk-theme-name = data.gtkTheme;
        };
      };
    }
    {
      name = "etc/xdg/alacritty/alacritty.yml";
      path = (pkgs.formats.yaml { }).generate "alacritty.yml" {
        live_config_reload = false;
        mouse.hide_when_typing = true;
        selection.save_to_clipboard = true;
        font = { normal.family = data.font; size = 16; };
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
          font = "${data.font}:size=10";
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
      extraGroups = [ "dialout" "wheel" ]
        ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
        ++ (lib.optional config.programs.adb.enable "adbusers")
        ++ (lib.optional config.programs.flashrom.enable "plugdev")
        ++ (lib.optional config.programs.wireshark.enable "wireshark")
        ++ (lib.optional config.virtualisation.docker.enable "docker")
      ;
    };

    home-manager.users.jared = { systemConfig, config, pkgs, ... }: {
      programs.git = {
        userEmail = "jaredbaur@fastmail.com";
        userName = systemConfig.users.users.jared.description;
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
          work = {
            user = "jbaur";
            hostname = "dev.work.home.arpa";
            dynamicForwards = [{ port = 9050; }];
            localForwards = [
              { bind.port = 1025; host.address = "localhost"; host.port = 1025; }
              { bind.port = 8000; host.address = "localhost"; host.port = 8000; }
            ];
          };
        };
      };
    };
  };
}
