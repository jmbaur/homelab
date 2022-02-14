{ config, lib, pkgs, ... }:
let
  cfg = config.custom.home;
  desktopEnabled = config.custom.desktop.enable;
in
with lib;
{
  options = {
    custom.home.enable = mkEnableOption "Enable custom home-manager configuration";
  };
  config = mkIf cfg.enable {
    home-manager.useUserPackages = true;
    home-manager.useGlobalPkgs = true;
    home-manager.users.jared = {
      home.packages = with pkgs; [
        age
        awscli2
        bat
        direnv
        dust
        exa
        fd
        fzf
        geteltorito
        gh
        git-get
        gmni
        gosee
        gotop
        grex
        gron
        htmlq
        jq
        keybase
        librespeed-cli
        mob
        mosh
        nix-prefetch-docker
        nix-prefetch-git
        nix-tree
        nixos-generators
        nnn
        nvme-cli
        openssl
        p
        patchelf
        picocom
        pstree
        pwgen
        ripgrep
        rtorrent
        sd
        sl
        smartmontools
        speedtest-cli
        sshfs
        stow
        tailscale
        tcpdump
        tea
        tealdeer
        tig
        tokei
        trash-cli
        unzip
        usbutils
        ventoy-bin
        vim
        xdg-user-dirs
        xdg-utils
        xsv
        ydiff
        yq
        yubikey-manager
        yubikey-personalization
        zf
        zip
        zoxide
      ] ++ (if desktopEnabled then
        (with pkgs; [
          bitwarden
          discord
          element-desktop
          fdroidcl
          ffmpeg-full
          firefox-wayland
          gobar
          grim
          hack-font
          imv
          libreoffice
          minecraft
          mpv
          plan9port
          signal-desktop
          slack
          slurp
          spotify
          thunderbird-wayland
          virt-manager
          wev
          wf-recorder
          winbox
          wine64
          wireshark
          wl-clipboard
          wtype
          xorg.xeyes
          zathura
        ]) else [ ]);

      home.sessionVariables.NNN_TRASH = "1";

      programs.ssh = {
        enable = true;
        controlMaster = "auto";
      };

      programs.bash = {
        enable = true;
        enableVteIntegration = true;
        historyControl = [ "ignoredups" ];
        shellAliases = { grep = "grep --color=auto"; };
      };
      programs.zsh.enable = true;
      programs.nushell.enable = true;

      programs.git = {
        enable = true;
        aliases = {
          st = "status --short --branch";
          di = "diff";
          br = "branch";
          co = "checkout";
          lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
        };
        delta.enable = true;
        delta.options.syntax-theme = "gruvbox-dark";
        extraConfig.pull.rebase = false;
        ignores = [ "*~" "*.swp" ];
        userEmail = "jaredbaur@fastmail.com";
        userName = "Jared Baur";
      };

      programs.tmux = {
        enable = true;
        aggressiveResize = true;
        baseIndex = 1;
        clock24 = true;
        disableConfirmationPrompt = true;
        escapeTime = 10;
        keyMode = "vi";
        prefix = "C-s";
        terminal = "screen-256color";
        shell = "\${SHELL}";
        plugins = with pkgs.tmuxPlugins; [ fingers logging ];
        extraConfig = ''
          set -g renumber-windows on
          set -g set-clipboard on
          set -g status-left-length 50
          set -g status-right "%H:%M %d-%b-%y"
          set-option -g focus-events on
          set-option -sa terminal-overrides ',xterm-256color:RGB'
        '';
      };

      programs.bat = {
        enable = true;
        config.theme = "gruvbox-dark";
      };

      programs.direnv = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };

      home.sessionVariables.SUMNEKO_ROOT_PATH = "${pkgs.sumneko-lua-language-server}";
      home.sessionVariables.EDITOR = "nvim";
      programs.neovim = {
        enable = true;
        vimAlias = true;
        vimdiffAlias = true;
        extraConfig = ''
          set termguicolors
          colorscheme gruvbox
        '';
        plugins =
          let
            # TODO(jared): Move the settings directory
            settings = pkgs.vimUtils.buildVimPlugin { name = "settings"; src = builtins.path { path = ../../modules/neovim/settings; }; };
            telescope-zf-native = pkgs.vimUtils.buildVimPlugin {
              name = "telescope-zf-native.nvim";
              src = pkgs.fetchFromGitHub {
                owner = "natecraddock";
                repo = "telescope-zf-native.nvim";
                rev = "76ae732e4af79298cf3582ec98234ada9e466b58";
                sha256 = "sha256-acV3sXcVohjpOd9M2mf7EJ7jqGI+zj0BH9l0DJa14ak=";
              };
            };
          in
          [ settings telescope-zf-native ]
          ++ (with pkgs.vimPlugins; [
            (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
            comment-nvim
            editorconfig-vim
            gruvbox-nvim
            lsp-colors-nvim
            lualine-nvim
            nvim-autopairs
            nvim-lspconfig
            nvim-treesitter-textobjects
            snippets-nvim
            telescope-nvim
            toggleterm-nvim
            trouble-nvim
            typescript-vim
            vim-better-whitespace
            vim-cue
            vim-dadbod
            vim-easy-align
            vim-eunuch
            vim-fugitive
            vim-lastplace
            vim-nix
            vim-repeat
            vim-rsi
            vim-surround
            vim-terraform
            vim-vinegar
            zig-vim
          ]);
        extraPackages = with pkgs; [
          bat
          black
          cargo
          clang-tools
          efm-langserver
          git
          go
          goimports
          gopls
          luaformatter
          nixpkgs-fmt
          nodePackages.typescript
          nodePackages.typescript-language-server
          nodejs
          pyright
          python3
          ripgrep
          rust-analyzer
          rustfmt
          shfmt
          sumneko-lua-language-server
          tree-sitter
          zig
          zls
        ];
      };

      programs.obs-studio = mkIf desktopEnabled {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [ wlrobs ];
      };

      programs.kitty = mkIf desktopEnabled {
        enable = true;
        font.name = "Hack";
        font.size = 14;
        settings = {
          copy_on_select = "yes";
          enable_audio_bell = "no";
          term = "xterm-256color";
          update_check_interval = 0;
        };
        extraConfig = ''
          include ${
            pkgs.fetchFromGitHub {
              owner = "dexpota";
              repo = "kitty-themes";
              rev = "b1abdd54ba655ef34f75a568d78625981bf1722c";
              sha256 = "1064hbg3dm45sigdp07chdfzxc25knm0mwbxz5y7sdfvaxkydh25";
            }
          }/themes/gruvbox_dark.conf
        '';
      };

      programs.chromium = mkIf desktopEnabled {
        enable = true;
        commandLineArgs = [ "--ozone-platform-hint=auto" ];
        extensions = [
          { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # vimium
          { id = "fmaeeiocbalinknpdkjjfogehkdcbkcd"; } # zoom-redirector
          { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
        ];
      };

      fonts.fontconfig.enable = mkIf desktopEnabled true;

      xdg.mimeApps = mkIf desktopEnabled {
        enable = true;
        defaultApplications = {
          "image/*" = [ "imv.desktop" ];
          "video/*" = [ "mpv.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
          "x-scheme-handler/chrome" = [ "firefox.desktop" ];
          "text/html" = [ "firefox.desktop" ];
          "application/x-extension-htm" = [ "firefox.desktop" ];
          "application/x-extension-html" = [ "firefox.desktop" ];
          "application/x-extension-shtml" = [ "firefox.desktop" ];
          "application/xhtml+xml" = [ "firefox.desktop" ];
          "application/x-extension-xhtml" = [ "firefox.desktop" ];
          "application/x-extension-xht" = [ "firefox.desktop" ];
          "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        };
      };

      gtk = mkIf desktopEnabled rec {
        enable = true;
        iconTheme.package = pkgs.gnome_themes_standard;
        iconTheme.name = "Adwaita";
        theme.package = pkgs.gnome_themes_standard;
        theme.name = "Adwaita-dark";
        gtk3.extraConfig = { gtk-key-theme-name = "Emacs"; };
        gtk4.extraConfig = gtk3.extraConfig;
      };

      # home.sessionVariables.NIXOS_OZONE_WL = "1";
      wayland.windowManager.sway = mkIf desktopEnabled {
        enable = true;
        systemdIntegration = true;
        wrapperFeatures.gtk = true;
        extraSessionCommands = ''
          # SDL:
          export SDL_VIDEODRIVER=wayland
          # QT (needs qt5.qtwayland in systemPackages):
          export QT_QPA_PLATFORM=wayland-egl
          export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
          # Fix for some Java AWT applications (e.g. Android Studio),
          # use this if they aren't displayed properly:
          export _JAVA_AWT_WM_NONREPARENTING=1
        '';
        extraConfig = ''
          output * bg ${builtins.fetchurl {
            url = "https://raw.githubusercontent.com/jonascarpay/Wallpapers/master/papes/34d34ee2b688a2e5dde8f3df1e4fec37c80b7d2b.jpg";
            sha256 = "1570n5ij78dvmfyfiman85vnb5syvxlv13iisspdaxi9ldrykjn1";
          }} fill
        '';
        config = rec {
          terminal = "${pkgs.kitty}/bin/kitty";
          modifier = "Mod4";
          workspaceAutoBackAndForth = true;
          window.titlebar = true;
          fonts = {
            names = [ "Hack" ];
            style = "Regular";
            size = 11.0;
          };
          seat = {
            "*" = {
              hide_cursor = "when-typing enable";
              xcursor_theme = "Adwaita 16";
            };
          };
          input."1:1:AT_Translated_Set_2_keyboard" = {
            xkb_options = "ctrl:nocaps";
            xkb_layout = "us";
          };
          input."1739:0:Synaptics_TM3276-022" = {
            accel_profile = "flat";
            dwt = "enabled";
            middle_emulation = "disabled";
            natural_scroll = "enabled";
            pointer_accel = "1";
            tap = "enabled";
          };
          defaultWorkspace = "workspace number 1";
          keybindings = lib.mkOptionDefault {
            "${modifier}+Control+l" = "exec ${pkgs.swaylock}/bin/swaylock -c 282828";
            "${modifier}+Control+space" = "exec ${pkgs.mako}/bin/makoctl dismiss --all";
            "${modifier}+Shift+s" = "sticky toggle";
            "${modifier}+c" = "exec ${pkgs.clipman}/bin/clipman pick --tool=CUSTOM --tool-args=\"${pkgs.bemenu}/bin/bemenu --line-height=25 --list=10\" | ${pkgs.findutils}/bin/xargs ${pkgs.sway}/bin/swaymsg exec --";
            "${modifier}+p" = "exec ${pkgs.bemenu}/bin/bemenu-run --line-height=25 --list=10 | ${pkgs.findutils}/bin/xargs ${pkgs.sway}/bin/swaymsg exec --";
            "${modifier}+tab" = "workspace back_and_forth";
            "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
            "XF86AudioMicMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
            "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
            "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 10%-";
            "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +10%";
          };
          floating.criteria = [
            { title = ".+[sS]haring (Indicator|your screen)"; }
            { window_role = "(pop-up|bubble|dialog)"; }
          ];
          bars = [{
            position = "top";
            statusCommand = "${pkgs.gobar}/bin/gobar";
            trayOutput = "*";
            inherit fonts;
            extraConfig = ''
              icon_theme Adwaita
            '';
          }];
        };
      };

      programs.mako = mkIf desktopEnabled {
        enable = true;
        defaultTimeout = 10000;
      };

      services.swayidle = mkIf desktopEnabled {
        enable = true;
        timeouts = [
          {
            timeout = 900;
            command = "${pkgs.swaylock}/bin/swaylock -c 282828";
          }
          {
            timeout = 905;
            command = "${pkgs.sway}/bin/swaymsg \"output * dpms off\"";
            resumeCommand = "${pkgs.sway}/bin/swaymsg \"output * dpms on\"";
          }
        ];
        events = [
          {
            event = "before-sleep";
            command = "${pkgs.swaylock}/bin/swaylock -c 282828";
          }
          {
            event = "lock";
            command = "${pkgs.swaylock}/bin/swaylock -c 282828";
          }
        ];
      };

      services.gammastep = mkIf desktopEnabled {
        enable = true;
        dawnTime = "6:00-7:45";
        duskTime = "18:35-20:15";
        provider = "geoclue2";
        temperature.day = 6500;
        temperature.night = 4000;
        settings.general.adjustment-method = "wayland";
      };

      systemd.user.services.clipman = mkIf desktopEnabled {
        Unit = {
          Description = "A clipboard manager for Wayland";
          PartOf = [ "graphical-session.target" ];
        };
        Install = {
          WantedBy = [ "sway-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = ''
            ${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store --no-persist
          '';
        };
      };

      services.kanshi = mkIf desktopEnabled {
        enable = true;
        profiles = {
          undocked.outputs = [{
            criteria = "eDP-1";
            status = "enable";
          }];
          docked.outputs = [
            {
              criteria = "eDP-1";
              status = "disable";
            }
            {
              criteria = "Lenovo Group Limited LEN P24q-20 V306P4GR";
              mode = "2560x1440@59.951Hz";
              status = "enable";
            }
          ];
        };
      };

      systemd.user.targets.tray = {
        Unit = {
          Description = "System tray";
          Documentation = [ "man:systemd.special(7)" ];
          Requires = [ "graphical-session-pre.target" ];
        };
      };

      services.udiskie.enable = desktopEnabled;
      services.udiskie.tray = "never";
    };

  };
}
