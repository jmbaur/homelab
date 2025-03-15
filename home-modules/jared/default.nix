{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (lib)
    getExe'
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.jared;
in
{
  options.jared = {
    includePersonalConfigs = mkEnableOption "personal configs" // {
      default = true;
    };

    dev.enable = mkEnableOption "dev";
  };

  config = mkMerge [
    {
      home.stateVersion = mkDefault "25.05";
      news.display = "silent";

      xdg.configFile."nix/nix.conf".text = ''
        nix-path = nixpkgs=${inputs.nixpkgs}
        experimental-features = nix-command flakes
      '';
      xdg.configFile."nix/registry.json".source = (pkgs.formats.json { }).generate "registry.json" {
        version = 2;
        flakes = [
          {
            exact = true;
            from = {
              id = "nixpkgs";
              type = "indirect";
            };
            to = {
              type = "path";
              path = inputs.nixpkgs.outPath;
              inherit (inputs.nixpkgs) lastModified rev narHash;
            };
          }
        ];
      };

      home.username = mkDefault "jared";
      home.homeDirectory = "/home/${config.home.username}";
    }

    (mkIf cfg.dev.enable {
      home.packages = with pkgs; [
        _caffeine
        abduco
        age-plugin-yubikey
        ansifilter
        as-tree
        bash-language-server
        bat
        binary-diff
        cachix
        carapace
        clang-tools
        cntr
        comma
        copy
        curl
        dig
        direnv
        fd
        file
        fsrx
        fzf
        gh
        git-extras
        git-gone
        gnumake
        go-tools
        gofumpt
        gopls
        grex
        gron
        htmlq
        inotify-tools
        jo
        jq
        just
        killall
        libarchive
        linux-scripts
        lrzsz
        lsof
        macgen
        man-pages
        man-pages-posix
        mdcat
        ncdu
        nil
        nix-diff
        nix-index
        nix-output-monitor
        nix-tree
        nixfmt-rfc-style
        nixos-kexec
        nixos-shell
        nload
        nmap
        nurl
        oils-for-unix
        pax-utils
        pb
        pciutils
        poke
        pomo
        procs
        pstree
        pwgen
        pyright
        qemu
        rage
        ripgrep
        ruff
        rust-analyzer
        rustfmt
        sd
        shellcheck
        shfmt
        strace-with-colors
        tcpdump
        tea
        tio
        tmux-jump
        tokei
        ttags
        unzip
        usbutils
        watchexec
        wip
        zip
        zls
      ];

      home.file.".sqliterc".text = ''
        .headers ON
        .mode columns
      '';

      xdg.configFile."fd/ignore".text = ''
        .git
      '';

      home.file.".bash_profile".text = ''
        source $HOME/.bashrc
      '';

      home.file.".bashrc".source = pkgs.substituteAll {
        src = ./bashrc.in;
        bashSensible = pkgs.bash-sensible;
        nixIndex = pkgs.nix-index;
        git = config.programs.git.package;
      };

      xdg.configFile."direnv/lib/hm-nix-direnv.sh".source =
        "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";

      programs.gpg = {
        enable = true;
        scdaemonSettings.disable-ccid = true;
      };

      programs.ssh = {
        enable = true;
        controlMaster = "auto";
        controlPersist = "30m";
        controlPath = "/run/user/%i/ssh-%C";
        matchBlocks."*.local" = {
          forwardAgent = true;
          proxyCommand = "${lib.getExe pkgs.ipv6-link-local-ssh-proxy-command} %h %p";
        };
      };

      programs.gh.enable = true;

      programs.git = {
        enable = true;
        userName = "Jared Baur";
        signing.format = lib.mkDefault "ssh";
        ignores = [
          "*.swp"
          "*~"
          ".direnv"
          ".envrc"
          ".exrc"
          ".nvim.lua"
          ".nvimrc"
          "Session.vim"
          "tags"
        ];
        aliases = {
          br = "branch";
          co = "checkout";
          di = "diff";
          dt = "difftool";
          lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
          st = "status --short --branch";
        };
        includes = mkIf cfg.includePersonalConfigs [
          {
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
          }
        ];
        extraConfig = {
          "difftool \"difftastic\"".cmd = "${getExe' pkgs.difftastic "difft"}  \"$LOCAL\" \"$REMOTE\"";
          "git-extras \"get\"".clone-path = "${config.xdg.stateHome}/projects";
          "url \"git+ssh://git@codeberg.com/\"".pushInsteadOf = "https://codeberg.org/";
          "url \"git+ssh://git@github.com/\"".pushInsteadOf = "https://github.com/";
          "url \"git+ssh://git@gitlab.com/\"".pushInsteadOf = "https://gitlab.com/";
          "url \"git+ssh://git@ssh.gitlab.gnome.org/\"".pushInsteadOf = "https://gitlab.gnome.org/";
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
          set-option -as terminal-features ",foot:RGB"
          set-option -as terminal-features ",rio:RGB"
          set-option -as terminal-features ",wezterm:RGB"
          set-option -as terminal-features ",xterm-256color:RGB"
          set-option -as terminal-features ",xterm-kitty:RGB"
          set-option -g allow-passthrough on
          set-option -g automatic-rename on
          set-option -g default-shell $SHELL
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
          bind-key j display-popup -E tmux-jump
        '';
      };

      # Enabling exrc support _must_ be done in the user's init.lua, it cannot
      # be done in a plugin.
      xdg.configFile."nvim/init.lua".source =
        pkgs.writeText "init.lua"
          # lua
          ''
            vim.opt.exrc = true
          '';

      xdg.configFile."alacritty/alacritty.toml".source = ./alacritty.toml;
      xdg.configFile."foot/foot.ini".source = ./foot.ini;
      xdg.configFile."ghostty/config".source = ./ghostty.conf;
      xdg.configFile."kitty/kitty.conf".source = ./kitty.conf;
      xdg.configFile."sway/config".source = ./sway.conf;
      xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;

      xdg.configFile."vim".source =
        pkgs.runCommand "vim-config" { env.VIM_PLUG = pkgs.vimPlugins.vim-plug; }
          ''
            cp -r ${./vim} $out; chmod +w $out
            install -Dm0644 -t $out/autoload ${pkgs.vimPlugins.vim-plug}/plug.vim 
          '';
    })
  ];
}
