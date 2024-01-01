{ config, lib, pkgs, ... }:
let
  cfg = config.jared;
in
{
  options.jared = {
    dev = {
      enable = lib.mkEnableOption "dev";
      includePersonalConfigs = lib.mkEnableOption "personal dev configs" // { default = true; };
    };

    gui.enable = lib.mkEnableOption "gui";
  };

  config = lib.mkMerge [
    {
      home.stateVersion = "24.05";

      home.username = lib.mkDefault "jared";
      home.homeDirectory = "/home/${config.home.username}";

      programs.home-manager.enable = true;

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set -U fish_greeting ""
        '';
      };

      home.packages = with pkgs; [
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
      ];
    }

    (lib.mkIf cfg.dev.enable {
      home.packages = with pkgs; [ ansifilter as-tree bc bintools bottom buildah cachix cntr curl deadnix diffsitter dig dnsutils dt entr fd file fsrx gh git-extras git-gone gnumake gosee grex gron htmlq htop-vim iputils jared-neovim-all-languages jo jq just killall lm_sensors lsof macgen mdcat mob mosh nix-diff nix-output-monitor nix-prefetch-scripts nix-tree nixos-generators nload nurl patchelf pb pciutils pd-notify podman-compose podman-tui pomo procs pstree qemu ripgrep rlwrap sd skopeo strace tcpdump tea tealdeer tig tio tmux-jump tokei traceroute usbutils wip xsv ydiff yj ];

      home.sessionVariables = {
        PROJECTS_DIR = "${config.home.homeDirectory}/projects";
        EDITOR = "nvim";
        NIX_PATH = "nixpkgs=${pkgs.path}";
      };
      home.shellAliases = {
        j = "tmux-jump";
      };

      home.file.".sqliterc".text = ''
        .headers ON
        .mode columns
      '';

      xdg.configFile."fd/ignore".text = ''
        .git
      '';

      programs.zoxide.enable = true;
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      programs.gpg = {
        enable = true;
        scdaemonSettings.disable-ccid = true;
      };

      programs.ssh = {
        enable = true;
        controlMaster = "auto";
        controlPersist = "30m";
        extraConfig = ''
          SetEnv TERM=xterm-256color
        '';
        matchBlocks = lib.optionalAttrs cfg.dev.includePersonalConfigs {
          "*.home.arpa" = {
            forwardAgent = true;
          };
        };
      };

      programs.gh.enable = true;
      programs.git = {
        enable = true;
        userName = "Jared Baur";
        ignores = [ "*~" "*.swp" ];
        aliases = {
          br = "branch";
          co = "checkout";
          di = "diff";
          dt = "difftool";
          lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
          st = "status --short --branch";
        };
        includes = lib.optional cfg.dev.includePersonalConfigs {
          contents =
            let
              primaryKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=";
              backupKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=";
            in
            rec {
              user.email = "jaredbaur@fastmail.com";
              user.signingKey = "key::${primaryKey}";
              commit.gpgSign = true;
              gpg.format = "ssh";
              "gpg \"ssh\"" = {
                defaultKeyCommand = "ssh-add -L";
                allowedSignersFile = pkgs.writeText "allowed-signers-file.txt" ''
                  ${user.email} ${primaryKey}
                  ${user.email} ${backupKey}
                '';
              };
            };
        };
        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          blame = {
            ignoreRevsFile = ".git-blame-ignore-revs";
            markIgnoredLines = true;
            markUnblamableLines = true;
          };
          "url \"git@github.com:\"".pushInsteadOf = "https://github.com/";
          "url \"git@gitlab.com:\"".pushInsteadOf = "https://gitlab.com/";
          "url \"git@codeberg.com:\"".pushInsteadOf = "https://codeberg.org/";
          pager.difftool = true;
          diff.tool = "difftastic";
          difftool.prompt = false;
          "difftool \"difftastic\"".cmd = "${lib.getExe' pkgs.difftastic "difft"}  \"$LOCAL\" \"$REMOTE\"";
          "git-extras \"get\"".clone-path = config.home.sessionVariables.PROJECTS_DIR;
        };
      };

      programs.tmux = {
        enable = true;
        aggressiveResize = true;
        baseIndex = 1;
        clock24 = true;
        disableConfirmationPrompt = true;
        escapeTime = 10;
        keyMode = "vi";
        historyLimit = 50000;
        prefix = "C-s";
        sensibleOnTop = false;
        terminal = "tmux-256color";
        plugins = with pkgs.tmuxPlugins; [ fingers logging ];
        extraConfig = ''
          set-option -ag terminal-overrides ",alacritty:Tc"
          set-option -ag terminal-overrides ",rio:Tc"
          set-option -g allow-passthrough on
          set-option -g automatic-rename on
          set-option -g detach-on-destroy off
          set-option -g renumber-windows on
          set-option -g set-clipboard on
          set-option -g set-titles on
          set-option -g set-titles-string "#{pane_title}"
          set-option -g status-keys emacs
          set-option -g status-left "[#{session_name}] "
          set-option -g status-left-length 50

          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi y send-keys -X copy-selection
          bind-key ESCAPE copy-mode
          bind-key J command-prompt -p "join pane from:"  "join-pane -h -s '%%'"
          bind-key W run-shell -b "${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts/session.sh switch"
          bind-key j display-popup -E -h 75% -w 75% -b double -T "Jump to:" "tmux-jump"
        '';
      };

      # services.emacs = {
      #   enable = false; # config.custom.dev.enable;
      #   startWithGraphical = false;
      #   package =
      #     let
      #       emacs = (pkgs.emacsPackagesFor pkgs.emacs29-nox).withPackages (epkgs: with epkgs; [
      #         clipetty
      #         company
      #         envrc
      #         evil
      #         evil-collection
      #         evil-commentary
      #         evil-surround
      #         go-mode
      #         magit
      #         markdown-mode
      #         nix-mode
      #         projectile
      #         rg
      #         rust-mode
      #         zig-mode
      #       ]);
      #     in
      #     pkgs.symlinkJoin {
      #       name = lib.appendToName "with-tools" emacs;
      #       paths = [ emacs ] ++ (with pkgs; [
      #         zls
      #         rust-analyzer
      #         gopls
      #         nil
      #         nixpkgs-fmt
      #       ]);
      #     };
      # };
    })

    (lib.mkIf cfg.gui.enable {
      fonts.fontconfig.enable = true;

      home.packages = with pkgs; [
        chromium-wayland
        firefox
        jetbrains-mono
        wl-clipboard
        xdg-terminal-exec
        (pkgs.writeShellScriptBin "greetd-launcher" ''
          ${lib.getExe' pkgs.systemd "systemd-cat"} --identifier=sway sway
        '')
      ];

      xdg.configFile."xdg-terminals.list".text = ''
        kitty.desktop
        Alacritty.desktop
      '';

      programs.kitty = {
        enable = true;
        settings = {
          background = "#14161b";
          clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
          copy_on_select = false;
          enable_audio_bell = false;
          font_family = "JetBrains Mono";
          font_size = 14;
          foreground = "#e0e2ea";
          shell_integration = "no-cursor";
          tab_bar_style = "powerline";
          update_check_interval = 0;
        };
      };

      programs.alacritty = {
        enable = true;
        settings = {
          live_config_reload = false;
          mouse.hide_when_typing = true;
          selection.save_to_clipboard = true;
          font = { normal.family = "JetBrains Mono"; size = 14; };
          terminal.osc52 = "CopyPaste";
          colors = lib.mapAttrsRecursive (_: color: "#${color}") {
            primary = { foreground = "e0e2ea"; background = "14161b"; };
          };
        };
      };

      programs.foot = {
        enable = true;
        settings = {
          main = {
            font = "JetBrains Mono:size=16";
            selection-target = "clipboard";
            notify-focus-inhibit = "no";
          };
          bell = {
            urgent = "yes";
            command-focused = "yes";
          };
          mouse.hide-when-typing = "yes";
          scrollback.indicator-position = "none";
          colors = { alpha = 1.0; foreground = "e0e2ea"; background = "14161b"; };
        };
      };

      xdg.userDirs = {
        enable = true;
        createDirectories = true;
      };

      programs.swaylock = {
        enable = true;
        settings.color = "333333";
      };

      services.swayidle = {
        enable = true;
      };

      gtk.enable = true;
      home.pointerCursor = {
        package = pkgs.gnome.gnome-themes-extra;
        name = "Adwaita";
        gtk.enable = true;
        x11.enable = true;
      };

      wayland.windowManager.sway = {
        enable = true;
        config = {
          modifier = "Mod4";
          terminal = "kitty";
          window.hideEdgeBorders = "smart";
          workspaceAutoBackAndForth = true;
          workspaceLayout = "stacking";
          input."type:keyboard" = {
            repeat_delay = "300";
            repeat_rate = "50";
            xkb_options = "ctrl:nocaps";
          };
        };
      };

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
    })
  ];
}
