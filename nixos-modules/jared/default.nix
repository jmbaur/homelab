{ lib, config, pkgs, ... }:
let
  cfg = config.custom.users.jared;
  guiData = import ../gui/data.nix;
  colors = guiData.colors.modus-vivendi;
in
{
  options.custom.users.jared = {
    enable = lib.mkEnableOption "jared";
    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = "jared";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;

    users.users.${cfg.username} = {
      inherit (cfg) passwordFile;

      isNormalUser = true;

      description = "Jared Baur";

      shell = pkgs.fish;

      openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];

      packages = with pkgs; ([
        (weechat.override { configure = { ... }: { scripts = with pkgs.weechatScripts; [ weechat-matrix ]; }; })
        age-plugin-yubikey
        croc
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
        tio
        tree
        unzip
        usbutils
        w3m
        wireguard-tools
        zip
      ] ++ lib.optionals config.custom.dev.enable [
        ansifilter
        as-tree
        bat
        bc
        bintools
        bottom
        buildah
        cachix
        cntr
        curl
        deadnix
        diffsitter
        dig
        direnv
        dnsutils
        entr
        fd
        file
        fsrx
        gh
        git
        git-extras
        git-get
        git-gone
        gnumake
        gosee
        grex
        gron
        htmlq
        htop-vim
        iputils
        ixio
        j
        jo
        jq
        just
        killall
        lm_sensors
        lsof
        macgen
        mdcat
        mob
        mosh
        neovim-all-languages
        nix-diff
        nix-prefetch-scripts
        nix-tree
        nixos-generators
        nload
        nurl
        openssl
        patchelf
        pciutils
        pd-notify
        podman-compose
        podman-tui
        pomo
        procs
        pstree
        qemu
        ripgrep
        rlwrap
        sd
        skopeo
        tcpdump
        tea
        tealdeer
        tig
        tokei
        traceroute
        usbutils
        wip
        xsv
        ydiff
        yj
      ]);

      extraGroups = [ "dialout" "wheel" "plugdev" ]
        ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
        ++ (lib.optional config.programs.adb.enable "adbusers")
        ++ (lib.optional config.programs.flashrom.enable "plugdev")
        ++ (lib.optional config.programs.wireshark.enable "wireshark")
        ++ (lib.optional config.virtualisation.docker.enable "docker")
      ;

      file.".config/kitty/kitty.conf".text = ''
        copy_on_select yes
        enable_audio_bell no
        font_family JetBrains Mono
        font_size 16
        include ${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Vivendi.conf
        shell_integration no-cursor
        tab_bar_style powerline
        update_check_interval 0
      '';

      file.".config/foot/foot.ini".source = (pkgs.formats.ini { }).generate "foot.ini" {
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

      file.".config/wezterm/wezterm.lua".source = ./wezterm.lua;
      file.".config/wezterm/colors/modus-vivendi.toml".source = (pkgs.formats.toml { }).generate "modus-vivendi.toml" {
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

      file.".config/alacritty/alacritty.yml".source = (pkgs.formats.yaml { }).generate "alacritty.yml" {
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

      file.".config/sway/config".source = pkgs.substituteAll {
        name = "sway.config";
        src = ./sway.config.in;
        inherit (config.services.xserver) xkbModel xkbOptions;
        # public domain monet paintings: https://commons.wikimedia.org/wiki/Claude_Monet_Paintings_in_Public_Domain
        wallpaper = pkgs.fetchurl {
          url = "https://upload.wikimedia.org/wikipedia/commons/8/84/Sainte-Adresse_A12549.jpg?download";
          sha256 = "sha256-uq9PbNVgfoSBtGCP27zS2ck4d52B7jLeDtyqPElKoS8=";
        };
      };

      file.".config/swaynag/config".text = ''
        font=JetBrains Mono 12
      '';

      file.".config/mako/config".text = ''
        max-visible=5
        sort=-time
        layer=overlay
        anchor=top-right
        font=JetBrains Mono 12
        width=500
        height=1000
        margin=10
        padding=5
        border-size=1
        border-radius=0
        icons=true
        icon-path=/run/current-system/sw/share/icons/Adwaita
        max-icon-size=64
        markup=true
        actions=true
        default-timeout=10000
        ignore-timeout=false

        [mode=do-not-disturb]
        invisible=1
      '';

      file.".config/gobar/gobar.yaml".source = (pkgs.formats.yaml { }).generate "gobar.yaml" {
        colorVariant = "dark";
        modules = [{ module = "network"; pattern = "(en|eth|wlp|wlan|wg)+"; }] ++
          (lib.optional config.custom.laptop.enable { module = "battery"; }) ++
          [
            { module = "memory"; }
            { module = "datetime"; timezones = [ "Local" "UTC" ]; }
          ];
      };

      file.".config/mimeapps.list".source = (pkgs.formats.ini { }).generate "mimeapps.list" {
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

      file.".sqliterc".text = ''
        .headers ON
        .mode columns
      '';

      file.".config/bat/config".text = ''
        --theme='base16'
      '';

      file.".config/fd/ignore".text = ''
        .git
      '';

      file.".config/fish/config.fish".text = ''
        if status is-interactive
          set -U fish_greeting ""
          ${pkgs.direnv}/bin/direnv hook fish | source
          ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source
        end
      '';

      file.".config/direnv/direnvrc".text = ''
        source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
      '';
    };

    home-manager.users.${cfg.username} = { nixosConfig, config, pkgs, ... }: {
      programs.git = {
        userEmail = lib.mkDefault "jaredbaur@fastmail.com";
        userName = nixosConfig.users.users.${cfg.username}.description;
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
