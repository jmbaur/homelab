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
      enable = config.custom.dev.enable;
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
        nvme-cli
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
        j
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
            target = ".config/dconf/user";
            path = pkgs.runCommand "dconf" { } ''
              mkdir dconf.d
              cp ${./dconf.conf} dconf.d/settings
              ${lib.getExe' pkgs.buildPackages.dconf "dconf"} compile $out dconf.d
            '';
          }
          {
            target = ".config/kitty/kitty.conf";
            path = pkgs.writeText "kitty.conf" ''
              copy_on_select yes
              enable_audio_bell no
              font_family monospace
              font_size 16
              shell_integration no-cursor
              tab_bar_style powerline
              update_check_interval 0

              background #1c1d23
              foreground #d7dae1
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
              scrollback.indicator-position = "none";
              colors = { alpha = 1.0; foreground = "d7dae1"; background = "1c1d23"; };
            };
          }
          {
            target = ".config/alacritty/alacritty.yml";
            path = (pkgs.formats.yaml { }).generate "alacritty.yml" {
              env.TERM = "xterm-256color"; # colors are weird in neovim without this
              live_config_reload = false;
              mouse.hide_when_typing = true;
              selection.save_to_clipboard = true;
              font = { normal.family = "monospace"; size = 16; };
              colors = lib.mapAttrsRecursive (_: color: "#${color}") {
                primary = { foreground = "d7dae1"; background = "1c1d23"; };
              };
            };
          }
          {
            target = ".config/labwc/autostart";
            path = pkgs.writeText "labwc-autostart" ''
              dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XCURSOR_THEME XCURSOR_SIZE NIXOS_OZONE_WL
              systemctl --user start labwc-session.target
            '';
          }
          {
            target = ".config/labwc/environment";
            path = pkgs.writeText "labwc-environment" ''
              QT_QPA_PLATFORM=wayland-egl
              QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
              SDL_VIDEODRIVER=wayland
              XCURSOR_SIZE=32
              XCURSOR_THEME=Adwaita
              XKB_DEFAULT_MODEL=${config.services.xserver.xkbModel}
              XKB_DEFAULT_OPTIONS=${config.services.xserver.xkbOptions}
              _JAVA_AWT_WM_NONREPARENTING=1
            '';
          }
          { target = ".config/waybar/style.css"; path = ./waybar-style.css; }
          {
            target = ".config/waybar/config";
            path = (pkgs.formats.json { }).generate "waybar-config.json" {
              height = 30;
              spacing = 4;
              modules-left = [ ];
              modules-center = [ "clock" ];
              modules-right = [ "network" "memory" "battery" "privacy" "tray" ];
              clock.format = "{:%F %H:%M}";
            };
          }
          {
            target = ".config/yambar/config.yml";
            path = (pkgs.formats.yaml { }).generate "yambar.yaml"
              (import ./yambar.nix (lib.optionalAttrs config.custom.laptop.enable {
                inherit (config.custom.laptop) batteries;
              }));
          }
          {
            target = ".config/labwc/rc.xml";
            path = pkgs.runCommand "labwc-rc.xml" { } ''
              ${lib.getExe pkgs.buildPackages.python3} ${./labwc-rc.py} > $out
            '';
          }
          {
            target = ".config/labwc/menu.xml";
            path = pkgs.runCommand "labwc-menu.xml" { } ''
              ${lib.getExe pkgs.buildPackages.python3} ${./labwc-menu.py} > $out
            '';
          }
          {
            target = ".config/sway/config";
            path = pkgs.substituteAll {
              name = "sway.config";
              src = ./sway.config.in;
              inherit (config.services.xserver) xkbModel xkbOptions;
            };
          }
          {
            target = ".config/swayidle/config";
            path =
              let
                lock = pkgs.writeShellScriptBin "lock" ''
                  ${lib.getExe pkgs.waylock} ${lib.escapeShellArgs [ "-fork-on-lock" "-init-color" "0x333333" "-input-color" "0x555555" "-fail-color" "0xFF0000" ]}
                '';
                conditionalSuspend = pkgs.writeShellScriptBin "conditional-suspend" (lib.optionalString config.custom.laptop.enable ''
                  if [[ "$(cat /sys/class/power_supply/AC/online)" -ne 1 ]]; then
                    echo "laptop is not on AC, suspending"
                    ${config.systemd.package}/bin/systemctl suspend
                  else
                    echo "laptop is on AC, not suspending"
                  fi
                '');
              in
              pkgs.writeText "swayidle.config" ''
                timeout 600 '${lib.getExe lock}'
                timeout 900 '${config.programs.sway.package}/bin/swaymsg "output * dpms off"' resume '${config.programs.sway.package}/bin/swaymsg "output * dpms on"'
                timeout 1200 '${lib.getExe conditionalSuspend}'
                before-sleep '${lib.getExe lock}'
                lock '${lib.getExe lock}'
                after-resume '${config.programs.sway.package}/bin/swaymsg "output * dpms on"'
              '';
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
              default-timeout=5000
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
          {
            target = ".config/tmux/tmux.conf";
            path = pkgs.substituteAll {
              name = "tmux.conf";
              src = ./tmux.conf.in;
              j = pkgs.j;
              inherit (pkgs.tmuxPlugins) logging fingers;
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
          {
            target = ".config/emacs/init.el";
            path = ./emacs.el;
          }
        ] ++ lib.optionals (config.custom.gui.enable && config.custom.gui.displays != { }) [
          {
            target = ".config/sway/config.d/shikane.config";
            path = pkgs.writeText "sway-shikane.config" ''
              exec_always shikane -o
            '';
          }
          {
            target = ".config/shikane/config.toml";
            path =
              let
                splitDisplays = lib.partition (disp: disp.isInternal) (lib.attrValues config.custom.gui.displays);
                internalDisplays = splitDisplays.right;
                externalDisplays = splitDisplays.wrong;
              in
              (pkgs.formats.toml { }).generate "shikane.toml" {
                profile = map
                  (profile: profile // {
                    exec = [ "${pkgs.libnotify}/bin/notify-send shikane \"Profile $SHIKANE_PROFILE_NAME has been applied\"" ];
                  })
                  ((lib.optional (externalDisplays != [ ]) {
                    name = "dock";
                    output = (map
                      (disp: { inherit (disp) match scale; enable = false; })
                      internalDisplays) ++ (map
                      (disp: { inherit (disp) match scale; enable = true; })
                      externalDisplays);
                  }) ++
                  (lib.optional (internalDisplays != [ ]) {
                    name = "laptop";
                    output = (map
                      (disp: { inherit (disp) match scale; enable = true; })
                      internalDisplays);
                  }));
              };
          }
        ]
        )
      );
  };
}
