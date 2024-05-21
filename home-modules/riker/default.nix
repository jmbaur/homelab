{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.jared;
in
{
  options.jared = with lib; {
    includePersonalConfigs = mkEnableOption "personal configs" // {
      default = true;
    };

    dev.enable = mkEnableOption "dev";

    desktop.enable = mkEnableOption "desktop";
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
          ];
        };
      };
      nixpkgs.overlays = [ inputs.nur.overlay ];

      home.username = lib.mkDefault "riker";
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
        (pkgs.writeShellScriptBin "copy" ''printf "\033]52;c;$(printf "%s" "$(cat)" | base64)\07"'')
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
      services.gpg-agent = {
        enable = true;
        pinentryPackage = if cfg.desktop.enable then pkgs.pinentry-gnome3 else pkgs.pinentry-tty;
      };

      home.packages = with pkgs; [
        ansifilter
        as-tree
        bc
        binary-diff
        bintools
        bottom
        cachix
        cntr
        curl
        dig
        dnsutils
        dt
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
        nixos-shell
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
        strace-with-colors
        systemctl-tui
        tcpdump
        tea
        tealdeer
        tig
        tio
        tmux-jump
        tokei
        traceroute
        usbutils
        watchexec
        wip
        xsv
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
          tag.sort = "creatordate";
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
          set-option -as terminal-features ",rio:RGB"
          set-option -as terminal-features ",wezterm:RGB"
          set-option -as terminal-features ",xterm-256color:RGB"
          set-option -as terminal-features ",xterm-kitty:RGB"
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

          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi y send-keys -X copy-selection
          bind-key ESCAPE copy-mode
          bind-key J command-prompt -p "join pane from:"  "join-pane -h -s '%%'"
          bind-key W run-shell -b "${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts/session.sh switch"
          bind-key j display-popup -E -h 75% -w 75% -b double -T "Jump to:" "tmux-jump"

        '';
      };

      xdg.configFile."emacs/init.el".source = ./emacs.el;

      # Enabling exrc support _must_ be done in the user's init.lua, it cannot
      # be done in a plugin.
      xdg.configFile."nvim/init.lua".source = pkgs.writeText "init.lua" ''
        vim.opt.exrc = true
      '';
    })
    (lib.mkIf cfg.desktop.enable {
      xdg.configFile."alacritty/alacritty.toml".source =
        (pkgs.formats.toml { }).generate "alacritty.toml"
          {
            colors.primary.background = "#000000";
            font.size = 14;
            selection.save_to_clipboard = true;
            terminal.osc52 = "CopyPaste";
          };
    })
  ];
}
