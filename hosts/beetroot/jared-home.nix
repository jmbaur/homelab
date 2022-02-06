{ config, lib, pkgs, ... }: {
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.jared = {
    home.packages = with pkgs; [
      age
      awscli2
      bat
      bitwarden
      direnv
      dust
      element-desktop
      exa
      fd
      fdroidcl
      ffmpeg-full
      firefox-wayland
      fzf
      geteltorito
      gh
      git-get
      gmni
      gosee
      gotop
      grex
      gron
      hack-font
      htmlq
      imv
      jq
      keybase
      librespeed-cli
      mob
      mosh
      mpv
      nix-direnv
      nix-prefetch-docker
      nix-prefetch-git
      nix-tree
      nixos-generators
      nnn
      nushell
      nvme-cli
      openssl
      p
      pass
      pass-git-helper
      patchelf
      picocom
      plan9port
      pstree
      pwgen
      ripgrep
      rtorrent
      scrot
      sd
      signal-desktop
      sl
      slack
      smartmontools
      speedtest-cli
      spotify
      stow
      tailscale
      tcpdump
      tea
      tealdeer
      thunderbird-wayland
      tig
      tokei
      trash-cli
      unzip
      usbutils
      ventoy-bin
      vim
      wf-recorder
      winbox
      wine64
      wireshark
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
      zsh
    ];

    home.sessionVariables.NNN_TRASH = "1";

    programs.ssh = {
      enable = true;
      controlMaster = "auto";
    };

    programs.bash = {
      enable = true;
      enableVteIntegration = true;
      historyControl = [ "ignoredups" ];
      historyFile = "${config.users.users.jared.home}/.bash_history";
      shellAliases = { grep = "grep --color=auto"; };
    };

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
      nix-direnv.enable = true;
    };

    home.sessionVariables.SUMNEKO_ROOT_PATH = "${pkgs.sumneko-lua-language-server}";
    home.sessionVariables.EDITOR = "nvim";
    programs.neovim = {
      enable = true;
      vimAlias = true;
      vimdiffAlias = true;
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
        [
          settings
          telescope-zf-native
        ] ++ (with pkgs.vimPlugins; [
          (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
          comment-nvim
          editorconfig-vim
          gruvbox-nvim
          lsp-colors-nvim
          lualine-nvim
          neogit
          nvim-autopairs
          nvim-lspconfig
          nvim-treesitter-textobjects
          snippets-nvim
          telescope-nvim
          toggleterm-nvim
          trouble-nvim
          typescript-vim
          vim-better-whitespace
          vim-clang-format
          vim-cue
          vim-dadbod
          vim-easy-align
          vim-eunuch
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

    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [ wlrobs ];
    };

    programs.kitty = {
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

    programs.chromium = {
      enable = true;
      commandLineArgs = [ "--ozone-platform-hint=auto" ];
      extensions = [
        { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # vimium
        { id = "fmaeeiocbalinknpdkjjfogehkdcbkcd"; } # zoom-redirector
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
      ];
    };

    fonts.fontconfig.enable = true;

    xdg.mimeApps = {
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

    gtk = {
      enable = true;
      iconTheme.package = pkgs.gnome_themes_standard;
      iconTheme.name = "Adwaita";
      theme.package = pkgs.gnome_themes_standard;
      theme.name = "Adwaita-dark";
      gtk3.extraConfig = { gtk-key-theme = "Emacs"; };
      gtk4.extraConfig = { gtk-key-theme = "Emacs"; };
    };

    # home.sessionVariables.NIXOS_OZONE_WL = "1";
    wayland.windowManager.sway = {
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
      config = rec {
        terminal = "${pkgs.kitty}/bin/kitty";
        modifier = "Mod4";
        workspaceAutoBackAndForth = true;
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
        input = {
          "1:1:AT_Translated_Set_2_keyboard" = {
            xkb_options = "ctrl:nocaps";
            xkb_layout = "us";
          };
          "1739:0:Synaptics_TM3276-022" = {
            natural_scroll = "enabled";
            dwt = "enabled";
            accel_profile = "flat";
            tap = "enabled";
            middle_emulation = "disabled";
          };
        };
        defaultWorkspace = "workspace number 1";
        keybindings = lib.mkOptionDefault {
          "${modifier}+p" = "exec ${pkgs.bemenu}/bin/bemenu-run --line-height=25 --list=10 | ${pkgs.findutils}/bin/xargs ${pkgs.sway}/bin/swaymsg exec --";
          "${modifier}+Control+l" = "exec ${pkgs.swaylock}/bin/swaylock -c 000000";
          "${modifier}+Control+space" = "exec makoctl dismiss --all";
          "${modifier}+c" = "exec ${pkgs.clipman}/bin/clipman pick --tool=${pkgs.bemenu}/bin/bemenu --tool-args=\"--line-height=25 --list=10\" | ${pkgs.findutils}/bin/xargs ${pkgs.sway}/bin/swaymsg exec --";
          "${modifier}+tab" = "workspace back_and_forth";
          "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "XF86AudioMicMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
          "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
          "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%";
        };
        floating.criteria = [{
          title = ".+[sS]haring (Indicator|your screen)";
          window_role = "(pop-up|bubble|dialog)";
        }];
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

    programs.mako = {
      enable = true;
      defaultTimeout = 10000;
    };

    services.swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 900;
          command = "${pkgs.swaylock}/bin/swaylock";
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
          command = "${pkgs.swaylock}/bin/swaylock";
        }
        {
          event = "lock";
          command = "${pkgs.swaylock}/bin/swaylock";
        }
      ];
    };

    services.wlsunset = {
      enable = true;
      gamma = "1.0";
      latitude = "34.0";
      longitude = "-118.0";
      temperature.day = 6500;
      temperature.night = 4000;
    };

    services.kanshi = {
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
            mode = "2560x1440@74.780Hz";
            status = "enable";
          }
        ];
      };
    };

  };
}

