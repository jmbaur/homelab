{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.jared;

  font = "sans";
  fontSize = 12.0;
in
{
  options.jared = with lib; {
    includePersonalConfigs = mkEnableOption "personal configs" // {
      default = true;
    };

    dev.enable = mkEnableOption "dev";

    gui = {
      enable = mkEnableOption "gui";
      defaultXkbOptions = mkOption {
        type = types.str;
        default = "ctrl:nocaps";
      };
    };
  };

  config = lib.mkMerge [
    {
      home.stateVersion = "24.05";

      nix = {
        package = pkgs.nix;
        registry.nixpkgs.flake = inputs.nixpkgs;
        settings = {
          nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
          experimental-features = [
            "nix-command"
            "flakes"
            "repl-flake"
          ];
        };
      };
      nixpkgs.overlays = [ inputs.nur.overlay ];

      home.username = lib.mkDefault "jared";
      home.homeDirectory = "/home/${config.home.username}";

      programs.home-manager.enable = true;

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set -U fish_greeting ""
          complete --command nom --wraps nix
        '';
      };

      home.packages = with pkgs; [
        age-plugin-yubikey
        croc
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
      home.packages = with pkgs; [
        ansifilter
        as-tree
        bc
        bintools
        bottom
        cachix
        cntr
        curl
        dig
        dnsutils
        dt
        entr
        fd
        file
        fsrx
        gh
        git-extras
        git-gone
        gnumake
        gosee
        grex
        gron
        htmlq
        htop-vim
        iputils
        jared-emacs
        jared-neovim-all-languages
        jo
        jq
        just
        killall
        libarchive
        lm_sensors
        lsof
        macgen
        man-pages
        man-pages-posix
        mdcat
        mob
        mosh
        nix-diff
        nix-output-monitor
        nix-prefetch-scripts
        nix-tree
        nload
        nurl
        patchelf
        pax-utils
        pb
        pciutils
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
        tmux-jump
        tokei
        traceroute
        usbutils
        wip
        xsv
        ydiff
        yj
      ];

      home.sessionVariables = {
        EDITOR = "nvim";
        GOPATH = "${config.home.homeDirectory}/.go";
        PROJECTS_DIR = "${config.home.homeDirectory}/projects";
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
        matchBlocks = lib.optionalAttrs cfg.includePersonalConfigs {
          "*.home.arpa" = {
            forwardAgent = true;
          };
        };
      };

      programs.gh.enable = true;
      programs.git = {
        enable = true;
        userName = "Jared Baur";
        ignores = [
          "*~"
          "*.swp"
          "Session.vim"
          ".nvim.lua"
          ".nvimrc"
          ".exrc"
        ];
        aliases = {
          br = "branch";
          co = "checkout";
          di = "diff";
          dt = "difftool";
          lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
          st = "status --short --branch";
        };
        includes = lib.optional cfg.includePersonalConfigs {
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
          "difftool \"difftastic\"".cmd = "${lib.getExe' pkgs.difftastic "difft"}  \"$LOCAL\" \"$REMOTE\"";
          "git-extras \"get\"".clone-path = config.home.sessionVariables.PROJECTS_DIR;
          "url \"git@codeberg.com:\"".pushInsteadOf = "https://codeberg.org/";
          "url \"git@github.com:\"".pushInsteadOf = "https://github.com/";
          "url \"git@gitlab.com:\"".pushInsteadOf = "https://gitlab.com/";
          blame.ignoreRevsFile = ".git-blame-ignore-revs";
          blame.markIgnoredLines = true;
          blame.markUnblamableLines = true;
          branch.sort = "-committerdate";
          commit.verbose = true;
          diff.algorithm = "histogram";
          diff.tool = "difftastic";
          difftool.prompt = false;
          fetch.fsckobjects = true;
          fetch.prune = true;
          fetch.prunetags = true;
          init.defaultBranch = "main";
          merge.conflictstyle = "zdiff3";
          pager.difftool = true;
          pull.rebase = true;
          push.autoSetupRemote = true;
          receive.fsckObjects = true;
          rerere.enabled = true;
          transfer.fsckobjects = true;
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
        plugins = with pkgs.tmuxPlugins; [
          fingers
          logging
        ];
        extraConfig = ''
          set-option -as terminal-features ",alacritty:RGB"
          set-option -as terminal-features ",xterm-kitty:RGB"
          set-option -as terminal-features ",rio:RGB"
          set-option -as terminal-features ",xterm-256color:RGB"
          set-option -g allow-passthrough on
          set-option -g automatic-rename on
          set-option -g detach-on-destroy off
          set-option -g focus-events on
          set-option -g renumber-windows on
          set-option -g set-clipboard on
          set-option -g set-titles on
          set-option -g set-titles-string "#{pane_title}"
          set-option -g status-justify left
          set-option -g status-keys emacs
          set-option -g status-left "[#{session_name}] "
          set-option -g status-left-length 90
          set-option -g status-right-length 90
          set-option -g status-style bg=default

          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi y send-keys -X copy-selection
          bind-key ESCAPE copy-mode
          bind-key J command-prompt -p "join pane from:"  "join-pane -h -s '%%'"
          bind-key W run-shell -b "${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts/session.sh switch"
          bind-key j display-popup -E -h 75% -w 75% -b double -T "Jump to:" "tmux-jump"

        '';
      };

      xdg.configFile."emacs/init.el".source = ./emacs.el;

      # so neovim doesn't complain that init.lua doesn't exist
      xdg.configFile."nvim/init.lua".source = pkgs.emptyFile;
    })

    (lib.mkIf cfg.gui.enable {
      fonts.fontconfig.enable = true;

      home.packages = with pkgs; [
        jetbrains-mono
        wl-clipboard
        xdg-terminal-exec
        (pkgs.writeShellScriptBin "caffeine" ''
          time=''${1:-infinity}
          echo "inhibiting idle for $time"
          systemd-inhibit --what=idle --who=caffeine --why=Caffeine --mode=block sleep "$time"
        '')
      ];

      xdg.configFile."xdg-terminals.list".text = ''
        kitty.desktop
        Alacritty.desktop
      '';

      programs.firefox = {
        enable = true;
        profiles.default = {
          extensions =
            with pkgs.nur.repos.rycee.firefox-addons;
            [ vimium ]
            ++ lib.optionals cfg.includePersonalConfigs [
              bitwarden
              privacy-badger
            ];
          settings = {
            "browser.newtabpage.enabled" = false;
            "browser.startup.homepage" = "chrome://browser/content/blanktab.html";
            "browser.tabs.inTitlebar" = 0;
            "signon.rememberSignons" = false;
          };
        };
      };

      programs.chromium = {
        enable = true;
        package = pkgs.chromium-wayland;
        extensions =
          [
            {
              # vimium
              id = "dbepggeogbaibhgnhhndojpepiihcmeb";
            }
          ]
          ++ lib.optionals cfg.includePersonalConfigs [
            {
              # bitwarden
              id = "nngceckbapebfimnlniiiahkandclblb";
            }
            {
              # privacy badger
              id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp";
            }
          ];
      };

      programs.kitty = {
        enable = true;
        shellIntegration.mode = "no-cursor";
        settings = {
          background = "#14161b";
          clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
          copy_on_select = true;
          enable_audio_bell = false;
          font_family = "JetBrains Mono";
          font_size = 14;
          foreground = "#e0e2ea";
          tab_bar_style = "powerline";
          update_check_interval = 0;
        };
      };

      programs.alacritty = {
        enable = true;
        settings = {
          live_config_reload = false;
          import = [ "${pkgs.alacritty-theme}/smoooooth.toml" ];
          mouse.hide_when_typing = true;
          selection.save_to_clipboard = true;
          font = {
            normal.family = "JetBrains Mono";
            size = 14;
          };
          terminal.osc52 = "CopyPaste";
          colors = lib.mapAttrsRecursive (_: color: "#${color}") {
            primary = {
              foreground = "e0e2ea";
              background = "14161b";
            };
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
          colors = {
            alpha = 1.0;
            foreground = "e0e2ea";
            background = "14161b";
          };
        };
      };

      xdg.userDirs = {
        enable = true;
        createDirectories = true;
      };

      programs.swaylock = {
        enable = true;
        settings.color = "222222";
      };

      programs.rofi = {
        enable = true;
        package = pkgs.rofi-wayland;
        font = "${font} ${toString fontSize}";
        theme = "android_notification";
        inherit (config.wayland.windowManager.sway.config) terminal;
      };

      services.swayidle =
        let
          lockCmd = "${lib.getExe config.programs.swaylock.package} -fF";
        in
        {
          enable = true;
          events = [
            {
              event = "before-sleep";
              command = lockCmd;
            }
            {
              event = "lock";
              command = lockCmd;
            }
          ];
          timeouts = [
            {
              timeout = 600;
              command = lockCmd;
            }
            {
              timeout = 900;
              command = "swaymsg output * power toggle";
              resumeCommand = "swaymsg output * power toggle";
            }
            {
              timeout = 1200;
              command = "systemctl suspend";
            }
          ];
        };

      services.mako = {
        enable = true;
        defaultTimeout = 10 * 1000; # 10s
        font = "${font} ${toString fontSize}";
      };

      services.cliphist.enable = true;

      services.gammastep = {
        enable = true;
        provider = "geoclue2";
      };

      systemd.user.services.yubikey-touch-detector = {
        Unit = {
          Description = "YubiKey touch notifier";
          Documentation = "https://github.com/maximbaz/yubikey-touch-detector";
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          Restart = "always";
          ExecStart = "${lib.getExe pkgs.yubikey-touch-detector} --libnotify";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      gtk = {
        enable = true;
        theme = {
          package = pkgs.gnome.gnome-themes-extra;
          name = "Adwaita-dark";
        };
      };

      qt = {
        enable = true;
        platformTheme = "gtk3";
        style = {
          name = "adwaita-dark";
          package = pkgs.adwaita-qt;
        };
      };

      home.pointerCursor = {
        package = pkgs.gnome.gnome-themes-extra;
        name = "Adwaita";
        gtk.enable = true;
        x11.enable = true;
      };

      wayland.windowManager.sway = {
        enable = true;
        package = null; # use sway from nixos configuration
        systemd.enable = true;
        extraConfig = ''
          bindgesture swipe:right workspace prev
          bindgesture swipe:left workspace next
        '';
        config =
          let
            modifier = config.wayland.windowManager.sway.config.modifier;
            shotman = lib.getExe' pkgs.shotman "shotman";
            hyprpicker = lib.getExe pkgs.hyprpicker;
            cliphist = lib.getExe config.services.cliphist.package;
            rofi = lib.getExe config.programs.rofi.package;
            wl-copy = lib.getExe' pkgs.wl-clipboard "wl-copy";
            notify-send = lib.getExe' pkgs.libnotify "notify-send";
            pamixer = lib.getExe pkgs.pamixer;
            brightnessctl = lib.getExe pkgs.brightnessctl;
          in
          {
            modifier = "Mod4";
            terminal = "kitty";
            menu = "${rofi} -show drun -show-icons";
            workspaceAutoBackAndForth = true;
            workspaceLayout = "stacking";
            defaultWorkspace = "workspace number 1";
            focus.wrapping = "yes";
            seat."*".xcursor_theme = with config.home.pointerCursor; "${name} ${toString size}";
            fonts = {
              names = [ font ];
              style = "Bold Semi-Condensed";
              size = fontSize;
            };
            bars = [
              {
                position = "top";
                trayOutput = "*";
                statusCommand = "${pkgs.i3status}/bin/i3status";
                # By using the same font and setting status_padding to 4, we get
                # a bar with the same height as window titlebars.
                inherit (config.wayland.windowManager.sway.config) fonts;
                extraConfig = ''
                  status_padding 4
                '';
              }
            ];
            window = {
              hideEdgeBorders = "smart";
              commands = [
                {
                  criteria.app_id = "^chrome-.*__.*";
                  command = "shortcuts_inhibitor disable";
                }
                {
                  criteria.shell = "xwayland";
                  command = ''title_format "%title (%shell)"'';
                }
              ];
            };
            output."*".background = "#222222 solid_color";
            input."type:pointer" = {
              accel_profile = "flat";
            };
            input."type:touchpad" = {
              natural_scroll = "enabled";
              dwt = "enabled";
              middle_emulation = "enabled";
              tap = "enabled";
            };
            input."type:keyboard" = {
              repeat_delay = "300";
              repeat_rate = "50";
              xkb_options = cfg.gui.defaultXkbOptions;
            };
            input."4617:13404:https://github.com/stapelberg_kinT_(kint41)" = {
              repeat_delay = "300";
              repeat_rate = "50";
              xkb_options = ''""''; # explicitly empty
            };
            modes = lib.mkOptionDefault { passthru."${modifier}+F12" = "mode default"; };
            keybindings = lib.mkOptionDefault (
              (lib.mapAttrs' (keys: lib.nameValuePair "${modifier}+${keys}") {
                "Control+l" = "exec loginctl lock-session";
                "F12" = "mode passthru";
                "Print" = "exec ${shotman} --capture window";
                "Shift+Print" = "exec ${shotman} --capture region";
                "Shift+b" = "bar mode toggle";
                "Shift+c" = "exec ${hyprpicker} --autocopy";
                "Shift+s" = "sticky toggle";
                "Tab" = "workspace back_and_forth";
                "c" = "exec ${cliphist} list | ${rofi} -i -p clipboard -dmenu -display-columns 2 | ${cliphist} decode | ${wl-copy}";
                "p" = "exec ${config.wayland.windowManager.sway.config.menu}";
              })
              // {
                "Print" = "exec ${shotman} --capture output";
                "XF86AudioMicMute" = ''exec ${notify-send} --transient --hint int:value:$(${pamixer} --default-source --toggle-mute --get-volume) --hint string:x-canonical-private-synchronous:mic mic "$(if [[ $(${pamixer} --default-source --get-mute) == true ]]; then echo muted; else echo unmuted; fi)"'';
                "XF86AudioMute" = ''exec ${notify-send} --transient --hint int:value:$(${pamixer} --toggle-mute --get-volume) --hint string:x-canonical-private-synchronous:volume volume "$(if [[ $(${pamixer} --get-mute) == true ]]; then echo muted; else echo unmuted; fi)"'';
                "XF86AudioRaiseVolume" = ''exec ${notify-send} --transient --hint int:value:$(${pamixer} --increase 5 --get-volume) --hint string:x-canonical-private-synchronous:volume volume'';
                "XF86AudioLowerVolume" = ''exec ${notify-send} --transient --hint int:value:$(${pamixer} --decrease 5 --get-volume) --hint string:x-canonical-private-synchronous:volume volume'';
                "XF86MonBrightnessUp" = ''exec ${notify-send} --transient --hint int:value:$(${brightnessctl} set +5% | sed -En "s/.*\(([0-9]+)%\).*/\1/p") --hint string:x-canonical-private-synchronous:brightness brightness'';
                "XF86MonBrightnessDown" = ''exec ${notify-send} --transient --hint int:value:$(${brightnessctl} set 5%- | sed -En "s/.*\(([0-9]+)%\).*/\1/p") --hint string:x-canonical-private-synchronous:brightness brightness'';
              }
            );
          };
      };

      xdg.configFile."labwc/autostart".text = ''
        dbus-update-activation-environment --systemd --all
        systemctl --user start labwc-session.target
      '';

      xdg.configFile."labwc/rc.xml".source = pkgs.runCommand "labwc-rc.xml" { } ''
        ${lib.getExe pkgs.buildPackages.python3} ${./labwc-rc.py} > $out
      '';

      xdg.configFile."labwc/menu.xml".source = pkgs.runCommand "labwc-rc.xml" { } ''
        ${lib.getExe pkgs.buildPackages.python3} ${./labwc-menu.py} > $out
      '';

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
    })
  ];
}
