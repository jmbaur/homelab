{ lib, config, pkgs, ... }:
let
  cfg = config.custom.users.jared;
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

    services.emacs = {
      enable = false; # config.custom.dev.enable;
      startWithGraphical = false;
      package =
        let
          emacs = (pkgs.emacsPackagesFor pkgs.emacs29-nox).withPackages (epkgs: with epkgs; [
            clipetty
            company
            envrc
            evil
            evil-collection
            evil-commentary
            evil-surround
            go-mode
            magit
            markdown-mode
            nix-mode
            projectile
            rg
            rust-mode
            zig-mode
          ]);
        in
        pkgs.symlinkJoin {
          name = lib.appendToName "with-tools" emacs;
          paths = [ emacs ] ++ (with pkgs; [
            zls
            rust-analyzer
            gopls
            nil
            nixpkgs-fmt
          ]);
        };
    };

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
        pwgen
        rage
        sl
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
        dt
        entr
        fd
        file
        fsrx
        gh
        git
        git-extras
        git-gone
        gnumake
        gosee
        grex
        gron
        htmlq
        htop-vim
        iputils
        jared-neovim-all-languages
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
        nix-diff
        nix-output-monitor
        nix-prefetch-scripts
        nix-tree
        nixos-generators
        nload
        nurl
        openssl
        patchelf
        pb
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
        tmux
        tmux-jump
        tokei
        traceroute
        usbutils
        wip
        xsv
        ydiff
        yj
        zoxide
      ]);

      extraGroups = [ "wheel" ]
        ++ (lib.optionals config.custom.dev.enable [ "dialout" "plugdev" ])
        ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
        ++ (lib.optional config.programs.adb.enable "adbusers")
        ++ (lib.optional config.programs.flashrom.enable "plugdev")
        ++ (lib.optional config.programs.wireshark.enable "wireshark")
        ++ (lib.optional config.virtualisation.docker.enable "docker")
      ;
    };

    programs.adb.enable = config.custom.gui.enable;

    # config files
    systemd.user.tmpfiles.users.${cfg.username}.rules = (map
      ({ target, path }: "L+ %h/${target} - - - - ${path}")
      ((lib.optionals config.custom.gui.enable [
        {
          target = ".config/xdg-terminals.list";
          path = pkgs.writeText "xdg-terminals.list" ''
            kitty.desktop
            alacritty.desktop
          '';
        }
        {
          target = ".config/kitty/kitty.conf";
          path = pkgs.writeText "kitty.conf" ''
            clipboard_control write-clipboard write-primary read-clipboard read-primary
            copy_on_select yes
            enable_audio_bell no
            font_family monospace
            font_size 16
            linux_display_server x11
            shell_integration no-cursor
            tab_bar_style powerline
            update_check_interval 0

            background #14161b
            foreground #e0e2ea
          '';
        }
        {
          target = ".config/alacritty/alacritty.toml";
          path = (pkgs.formats.toml { }).generate "alacritty-config.toml" {
            live_config_reload = false;
            mouse.hide_when_typing = true;
            selection.save_to_clipboard = true;
            font = { normal.family = "monospace"; size = 16; };
            colors = lib.mapAttrsRecursive (_: color: "#${color}") {
              primary = { foreground = "e0e2ea"; background = "14161b"; };
            };
          };
        }
        {
          target = ".config/rio/config.toml";
          path = (pkgs.formats.toml { }).generate "rio-config.toml" {
            use-kitty-keyboard-protocol = true;
            fonts = {
              # TODO(jared): setting "monospace" doesn't work...
              family = "JetBrains Mono";
              size = 28;
            };
            colors = rec {
              background = "#14161b";
              foreground = "#e0e2ea";
              selection-background = foreground; # "#1f1f1f";
              selection-foreground = background; # "#d6dbe5";
              cursor = "#b9b9b9";
              black = "#1f1f1f";
              red = "#f81118";
              green = "#2dc55e";
              yellow = "#ecba0f";
              blue = "#2a84d2";
              magenta = "#4e5ab7";
              cyan = "#1081d6";
              white = "#d6dbe5";
              light_black = "#d6dbe5";
              light_red = "#de352e";
              light_green = "#1dd361";
              light_yellow = "#f3bd09";
              light_blue = "#1081d6";
              light_magenta = "#5350b9";
              light_cyan = "#0f7ddb";
              light_white = "#ffffff";
            };
          };
        }
        # {
        #   target = ".config/foot/foot.ini";
        #   path = (pkgs.formats.ini { }).generate "foot.ini" {
        #     main = {
        #       font = "monospace:size=16";
        #       selection-target = "clipboard";
        #       notify-focus-inhibit = "no";
        #     };
        #     bell = {
        #       urgent = "yes";
        #       command-focused = "yes";
        #     };
        #     mouse.hide-when-typing = "yes";
        #     scrollback.indicator-position = "none";
        #     colors = { alpha = 1.0; foreground = "e0e2ea"; background = "14161b"; };
        #   };
        # }
        # {
        #   target = ".config/labwc/autostart";
        #   path = pkgs.writeText "labwc-autostart" ''
        #     dbus-update-activation-environment --systemd --all
        #     systemctl --user start labwc-session.target
        #   '';
        # }
        # {
        #   target = ".config/labwc/rc.xml";
        #   path = pkgs.runCommand "labwc-rc.xml" { } ''
        #     ${lib.getExe pkgs.buildPackages.python3} ${./labwc-rc.py} > $out
        #   '';
        # }
        # {
        #   target = ".config/labwc/menu.xml";
        #   path = pkgs.runCommand "labwc-menu.xml" { } ''
        #     ${lib.getExe pkgs.buildPackages.python3} ${./labwc-menu.py} > $out
        #   '';
        # }
        # {
        #   target = ".config/sway/config";
        #   path = pkgs.substituteAll {
        #     name = "sway.config";
        #     src = ./sway.config.in;
        #     inherit (config.services.xserver.xkb) model options;
        #   };
        # }
        # {
        #   target = ".config/swayidle/config";
        #   path =
        #     let
        #       dpms-all = pkgs.writeShellScriptBin "dpms-all" ''
        #         ${lib.getExe pkgs.wlopm} --json |
        #           jq --raw-output '.[].output' |
        #           xargs -n1 ${lib.getExe pkgs.wlopm} $1
        #       '';
        #       lock = pkgs.writeShellScriptBin "lock" ''
        #         ${lib.getExe pkgs.waylock} ${lib.escapeShellArgs [ "-fork-on-lock" "-init-color" "0x333333" "-input-color" "0x555555" "-fail-color" "0xFF0000" ]}
        #       '';
        #       conditionalSuspend = pkgs.writeShellScriptBin "conditional-suspend" (lib.optionalString config.custom.laptop.enable ''
        #         if [[ "$(cat /sys/class/power_supply/AC/online)" -ne 1 ]]; then
        #           echo "laptop is not on AC, suspending"
        #           ${config.systemd.package}/bin/systemctl suspend
        #         else
        #           echo "laptop is on AC, not suspending"
        #         fi
        #       '');
        #     in
        #     pkgs.writeText "swayidle.config" ''
        #       timeout 600 '${lib.getExe lock}'
        #       timeout 900 '${lib.getExe dpms-all} --off' resume '${lib.getExe dpms-all} --on'
        #       timeout 1200 '${lib.getExe conditionalSuspend}'
        #       before-sleep '${lib.getExe lock}'
        #       lock '${lib.getExe lock}'
        #       after-resume '${lib.getExe dpms-all} --on'
        #     '';
        # }
        # {
        #   target = ".config/swaynag/config";
        #   path = pkgs.writeText "swaynag.config" ''
        #     font=sans 12
        #   '';
        # }
        # {
        #   target = ".config/gobar/gobar.yaml";
        #   path = (pkgs.formats.yaml { }).generate "gobar.yaml" {
        #     colorVariant = "dark";
        #     modules = [{ module = "network"; pattern = "(en|eth|wlp|wlan|wg)+"; }] ++
        #     (lib.optional config.custom.laptop.enable { module = "battery"; }) ++
        #     [
        #       { module = "memory"; }
        #       { module = "datetime"; timezones = [ "Local" "UTC" ]; }
        #     ];
        #   };
        # }
        # {
        #   target = ".config/mimeapps.list";
        #   path = (pkgs.formats.ini { }).generate "mimeapps.list" {
        #     "Added Associations" = { };
        #     "Removed Associations" = { };
        #     "Default Applications" = {
        #       "application/pdf" = "firefox.desktop";
        #       "audio/*" = "mpv.desktop";
        #       "image/jpeg" = "imv.desktop";
        #       "image/png" = "imv.desktop";
        #       "text/*" = "nvim.desktop";
        #       "video/*" = "mpv.desktop";
        #       "text/html" = "firefox.desktop";
        #       "x-scheme-handler/http" = "firefox.desktop";
        #       "x-scheme-handler/https" = "firefox.desktop";
        #     };
        #   };
        # }
        # {
        #   target = ".config/rofi/config.rasi";
        #   path = pkgs.writeText "rofi.rasi" ''
        #     configuration {
        #       font: "sans 12";
        #     }
        #     @theme "Arc"
        #   '';
        # }
      ]) ++ [
        { target = ".config/emacs/init.el"; path = ./emacs.el; }
        {
          target = ".config/tmux/tmux.conf";
          path = pkgs.substituteAll {
            name = "tmux.conf";
            src = ./tmux.conf.in;
            tmuxJump = pkgs.tmux-jump;
            tmuxLogging = pkgs.tmuxPlugins.logging;
            tmuxFingers = pkgs.tmuxPlugins.fingers;
            tmuxFzf = pkgs.tmuxPlugins.tmux-fzf;
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
          target = ".config/fd/ignore";
          path = pkgs.writeText "fdignore.config" ''
            .git
          '';
        }
        {
          target = ".config/fish/config.fish";
          path =
            let
              direnvHook = pkgs.runCommand "direnv-hook.fish" { } "${lib.getExe pkgs.direnv} hook fish > $out";
              zoxideHook = pkgs.runCommand "zoxide-hook.fish" { } "${lib.getExe pkgs.zoxide} init fish > $out";
            in
            pkgs.writeText "fish.config" ''
              if status is-interactive
                set -U fish_greeting ""
                ${lib.optionalString config.custom.dev.enable ''
                source ${direnvHook}
                source ${zoxideHook}
                set -U PROJECTS_DIR ${config.users.users.${cfg.username}.home}/projects
                alias j tmux-jump
                ''}
              end
            '';
        }
        {
          target = ".config/zellij/config.kdl";
          path = ./zellij-config.kdl;
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
            direnvHook = pkgs.runCommand "direnv-hook.zsh" { } "${lib.getExe pkgs.direnv} hook zsh > $out";
            zoxideHook = pkgs.runCommand "zoxide-hook.zsh" { } "${lib.getExe pkgs.zoxide} init zsh > $out";
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
            inherit (config.users.users.${cfg.username}) home;
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
      ])
    );
  };
}
