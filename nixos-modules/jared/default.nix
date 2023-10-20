{ lib, config, pkgs, ... }:
let
  cfg = config.custom.users.jared;
  colors = (import ./colors.nix).modus-vivendi;
in
{
  options.custom.users.jared = with lib; {
    enable = mkEnableOption "jared";
    hashedPasswordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
    };
    username = mkOption {
      type = types.str;
      default = "jared";
    };
    git = {
      email = mkOption {
        type = types.str;
        default = "jaredbaur@fastmail.com";
      };
      signingKey = mkOption {
        type = types.str;
        default = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=";
      };
      signCommits = mkEnableOption "sign git commits" // { default = true; };
      allowedSignersFile = mkOption {
        type = types.path;
        default = pkgs.writeText "allowed-signers-file.txt" ''
          jaredbaur@fastmail.com sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
          jaredbaur@fastmail.com sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
        '';
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = config.users.mutableUsers;
      message = "Setting `users.users.${cfg.username}.initialPassword` with `users.mutableUsers = true;` is not safe!";
    }];

    programs.fish.enable = true;

    users.users.${cfg.username} = {
      isNormalUser = true;

      description = "Jared Baur";

      initialPassword = cfg.username;

      shell = pkgs.fish;

      openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];

      packages = with pkgs; ([
        age-plugin-yubikey
        croc
        gmni
        iperf3
        librespeed-cli
        nmap
        nvme-cli
        pwgen
        rage
        sl
        tailscale
        tcpdump
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
        nix-output-monitor
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
        strace
        tcpdump
        tea
        tealdeer
        tig
        tio
        tokei
        traceroute
        usbutils
        wip
        xsv
        ydiff
        yj
      ] ++ lib.optionals config.custom.gui.enable [
        luakit
      ]);

      extraGroups = [ "dialout" "wheel" "plugdev" ]
        ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
        ++ (lib.optional config.programs.adb.enable "adbusers")
        ++ (lib.optional config.programs.flashrom.enable "plugdev")
        ++ (lib.optional config.programs.wireshark.enable "wireshark")
        ++ (lib.optional config.virtualisation.docker.enable "docker")
      ;
    };

    programs.adb.enable = config.custom.gui.enable;

    systemd.user.tmpfiles.users.${cfg.username}.rules =
      # xdg user dirs
      (lib.optionals config.custom.gui.enable (map
        # don't apply any cleanup
        (dir: "d %h/${dir} 0755 ${config.users.users.${cfg.username}.name} ${config.users.users.${cfg.username}.group} - -")
        [
          "Desktop"
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Public"
          "Templates"
          "Videos"
        ])) ++
      # config files
      (map
        ({ target, path }: "L+ %h/${target} - - - - ${path}")
        ([
          {
            target = ".config/kitty/kitty.conf";
            path =
              let
                # keep kitty default tab and selection colors
                modusVivendi = pkgs.runCommand "modus_vivendi.conf" { } ''
                  grep -vi -e tab -e select ${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Vivendi.conf > $out
                '';
              in
              pkgs.writeText "kitty.conf" ''
                copy_on_select yes
                enable_audio_bell no
                font_family monospace
                font_size 16
                include ${modusVivendi}
                shell_integration no-cursor
                tab_bar_style powerline
                update_check_interval 0
              '';
          }
          {
            target = ".config/foot/foot.ini";
            path = (pkgs.formats.ini { }).generate "foot.ini" {
              main = {
                font = "monospace:size=16";
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
            target = ".config/wezterm/wezterm.lua";
            path = ./wezterm.lua;
          }
          {
            target = ".config/wezterm/colors/modus-vivendi.toml";
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
          {
            target = ".config/rio/config.toml";
            path = (pkgs.formats.toml { }).generate "rio.toml" {
              fonts = {
                size = 28;
                family = "monospace";
              };
              colors = {
                selection-foreground = "#FFFFFF";
                selection-background = "#5C5C5C";
                tabs = "#2F2F2F";
                tabs-active = "#545454";
                foreground = "#${colors.foreground}";
                background = "#${colors.background}";
                black = "#${colors.regular0}";
                red = "#${colors.regular1}";
                green = "#${colors.regular2}";
                yellow = "#${colors.regular3}";
                blue = "#${colors.regular4}";
                magenta = "#${colors.regular5}";
                cyan = "#${colors.regular6}";
                white = "#${colors.regular7}";
                light-black = "#${colors.bright0}";
                light-red = "#${colors.bright1}";
                light-green = "#${colors.bright2}";
                light-yellow = "#${colors.bright3}";
                light-blue = "#${colors.bright4}";
                light-magenta = "#${colors.bright5}";
                light-cyan = "#${colors.bright6}";
                light-white = "#${colors.bright7}";
              };
            };
          }
          {
            target = ".config/alacritty/alacritty.yml";
            path = (pkgs.formats.yaml { }).generate "alacritty.yml" {
              live_config_reload = false;
              mouse.hide_when_typing = true;
              selection.save_to_clipboard = true;
              font = { normal.family = "monospace"; size = 16; };
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
            target = ".config/sway/config";
            path = pkgs.substituteAll {
              name = "sway.config";
              src = ./sway.config.in;
              terminal = "kitty";
              inherit (config.services.xserver) xkbModel xkbOptions;
            };
          }
          {
            target = ".config/swaynag/config";
            path = pkgs.writeText "swaynag.config" ''
              font=sans 12
            '';
          }
          {
            target = ".config/mako/config";
            path = pkgs.writeText "mako.config" ''
              max-visible=5
              sort=-time
              layer=overlay
              anchor=top-right
              font=sans 12
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
          }
          {
            target = ".config/gobar/gobar.yaml";
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
            target = ".config/mimeapps.list";
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
            target = ".sqliterc";
            path = pkgs.writeText "sqliterc" ''
              .headers ON
              .mode columns
            '';
          }
          {
            target = ".config/bat/config";
            path = pkgs.writeText "bat.config" ''
              --theme='base16'
            '';
          }
          {
            target = ".config/fd/ignore";
            path = pkgs.writeText "fdignore.config" ''
              .git
            '';
          }
          {
            target = ".config/fish/config.fish";
            path =
              let
                nixYourShell = pkgs.runCommand "nix-your-shell.fish" { } "${pkgs.nix-your-shell}/bin/nix-your-shell fish > $out";
                direnvHook = pkgs.runCommand "direnv-hook.fish" { } "${pkgs.direnv}/bin/direnv hook fish > $out";
              in
              pkgs.writeText "fish.config" ''
                if status is-interactive
                  set -U fish_greeting ""
                  ${lib.optionalString config.custom.dev.enable ''
                  source ${nixYourShell}
                  source ${direnvHook}
                  set -U PROJECTS_DIR ${config.users.users.${cfg.username}.home}/projects
                  ''}
                end
              '';
          }
          {
            target = ".config/zellij/config.kdl";
            path = ./zellij-config.kdl;
          }
          {
            target = ".config/starship.toml";
            path = (pkgs.formats.toml { }).generate "starship.toml" {
              add_newline = false;
              format = "$username$hostname$directory$git_branch$git_commit$git_state$git_metrics$git_status$character";
            };
          }
          {
            target = ".config/nushell/env.nu";
            path = ./nushell-env.nu;
          }
          {
            target = ".config/nushell/config.nu";
            path = pkgs.substituteAll {
              name = "config.nu";
              src = ./nushell-config.nu.in;
              inherit (pkgs) nu_scripts;
              starshipInit = pkgs.runCommand "starship-init.nu" { } ''
                ${pkgs.starship}/bin/starship init nu > $out
              '';
            };
          }
          {
            target = ".zshenv";
            path = pkgs.writeText "zshenv" ''
              export EDITOR=nvim
            '';
          }
          {
            target = ".zshrc";
            path = pkgs.substituteAll {
              name = "zshrc";
              src = ./rc.zsh.in;
              nixYourShell = pkgs.runCommand "nix-your-shell.zsh" { } "${pkgs.nix-your-shell}/bin/nix-your-shell zsh > $out";
              direnvHook = pkgs.runCommand "direnv-hook.zsh" { } "${pkgs.direnv}/bin/direnv hook zsh > $out";
            };
          }
          {
            target = ".config/direnv/direnvrc";
            path = pkgs.writeText "direnvrc" ''
              source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
            '';
          }
          {
            target = ".ssh/config";
            path = pkgs.writeText "ssh.config" ''
              SetEnv TERM=xterm-256color

              Host *.home.arpa
                ForwardAgent yes

              Host *
                ForwardAgent no
                Compression no
                ServerAliveInterval 0
                ServerAliveCountMax 3
                HashKnownHosts no
                UserKnownHostsFile ~/.ssh/known_hosts
                ControlMaster auto
                ControlPath ~/.ssh/master-%r@%n:%p
                ControlPersist 30m
            '';
          }
          {
            target = ".gnupg/scdaemon.conf";
            path = pkgs.writeText "scdaemon.conf" ''
              disable-ccid
            '';
          }
          {
            target = ".gnupg/gpg.conf";
            path = pkgs.writeText "gpg.conf" ''
              cert-digest-algo SHA512
              charset utf-8
              default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
              fixed-list-mode
              keyid-format 0xlong
              list-options show-uid-validity
              no-comments
              no-emit-version
              no-symkey-cache
              personal-cipher-preferences AES256 AES192 AES
              personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
              personal-digest-preferences SHA512 SHA384 SHA256
              require-cross-certification
              s2k-cipher-algo AES256
              s2k-digest-algo SHA512
              use-agent
              verify-options show-uid-validity
              with-fingerprint
            '';
          }
          {
            target = ".config/git/config";
            path = pkgs.substituteAll {
              name = "git.config";
              src = ./git.config.in;
              difftastic = pkgs.difftastic;
              gh = pkgs.gh;
              userName = config.users.users.${cfg.username}.description;
              inherit (cfg.git) email signingKey allowedSignersFile extraConfig;
              signCommits = lib.boolToString cfg.git.signCommits;
            };
          }
          {
            target = ".config/git/ignore";
            path = pkgs.writeText "gitignore.config" ''
              *~
              *.swp
            '';
          }
          {
            target = ".config/tmux/tmux.conf";
            path = pkgs.substituteAll {
              name = "tmux.conf";
              src = ./tmux.conf.in;
              sensible = pkgs.tmuxPlugins.sensible;
              logging = pkgs.tmuxPlugins.logging;
              j = pkgs.j;
            };
          }
          {
            target = ".config/rofi/config.rasi";
            path = pkgs.writeText "rofi.rasi" ''
              configuration {
                font: "sans 12";
              }
            '';
          }
        ] ++ lib.optional (config.custom.laptop.enable && config.custom.laptop.displays != { }) {
          target = ".config/shikane/config.toml";
          path =
            let
              splitDisplays = lib.partition (disp: disp.isInternal) (lib.attrValues config.custom.laptop.displays);
              internalDisplays = splitDisplays.right;
              externalDisplays = splitDisplays.wrong;
            in
            (pkgs.formats.toml { }).generate "shikane.toml" {
              profile = map
                (profile: profile // {
                  exec = [
                    "${pkgs.libnotify}/bin/notify-send shikane \"Profile $SHIKANE_PROFILE_NAME has been applied\""
                  ];
                }) [
                {
                  name = "dock";
                  output = (map
                    (disp: { inherit (disp) match; enable = false; })
                    internalDisplays) ++ (map
                    (disp: { inherit (disp) match; enable = true; })
                    externalDisplays);
                }
                {
                  name = "laptop";
                  output = (map
                    (disp: { inherit (disp) match; enable = true; })
                    internalDisplays);
                }
              ];
            };
        })
      );
  };
}

