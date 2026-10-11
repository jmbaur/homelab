{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    {
      nixpkgs.config.allowUnfree = true;

      home.packages = [
        pkgs.ansifilter
        pkgs.as-tree
        pkgs.awscli2
        pkgs.bat
        pkgs.carapace
        pkgs.claude-code
        pkgs.comma
        pkgs.curl
        pkgs.difftastic
        pkgs.dig
        pkgs.direnv
        pkgs.fd
        pkgs.file
        pkgs.fsrx
        pkgs.gh
        pkgs.git
        pkgs.git-absorb
        pkgs.git-extras
        pkgs.git-gone
        pkgs.gnumake
        pkgs.grex
        pkgs.gron
        pkgs.hexyl
        pkgs.home-manager
        pkgs.homelab-utils.copy
        pkgs.homelab-utils.macgen
        pkgs.homelab-utils.nix-key
        pkgs.homelab-utils.pb
        pkgs.homelab-utils.pomo
        pkgs.htmlq
        pkgs.htop
        pkgs.jared-neovim
        pkgs.jq
        pkgs.just
        pkgs.killall
        pkgs.libarchive
        pkgs.linux-scripts
        pkgs.lrzsz
        pkgs.lsof
        pkgs.man-pages
        pkgs.man-pages-posix
        pkgs.moor
        pkgs.ncdu
        pkgs.nix-diff
        pkgs.nix-tree
        pkgs.nixos-shell
        pkgs.nmap
        pkgs.nurl
        pkgs.oils-for-unix
        pkgs.pciutils
        pkgs.pi-coding-agent
        pkgs.procs
        pkgs.pstree
        pkgs.pwgen
        pkgs.qemu
        pkgs.rage
        pkgs.renameutils
        pkgs.ripgrep
        pkgs.rsbkb
        pkgs.sd
        pkgs.tcpdump
        pkgs.tea
        pkgs.tinyxxd
        pkgs.tio
        pkgs.tmux
        pkgs.tokei
        pkgs.unzip
        pkgs.usbutils
        pkgs.watchexec
        pkgs.zip
      ];

      home.sessionVariables.EDITOR = "vim";

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."Host *.internal".ForwardAgent = true;
        settings."Host *.local".ForwardAgent = true;
        settings."Host i-* mi-*".ProxyCommand =
          "${pkgs.runtimeShell} -c \"${lib.getExe pkgs.awscli2} ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'\"";
        settings."Host *" = {
          ServerAliveInterval = 11;
          ControlMaster = "auto";
          ControlPath = "/tmp/ssh-%i-%C";
          ControlPersist = "30m";
        };
      };

      programs.git = {
        enable = true;
        iniContent = {
          alias = {
            br = "branch";
            co = "checkout";
            di = "diff";
            dt = "difftool";
            lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
            st = "status --short --branch";
          };
          blame = {
            ignoreRevsFile = ".git-blame-ignore-revs";
            markIgnoredLines = true;
            markUnblamableLines = true;
          };
          core.excludesFile = pkgs.writeText "gitignore" (
            lib.concatLines [
              "*.elc"
              "*.swp"
              "*~"
              ".direnv"
              ".envrc"
              ".exrc"
              ".nvim.lua"
              ".nvimrc"
              "Session.vim"
              "tags"
            ]
          );
          branch.sort = "-committerdate";
          commit.verbose = true;
          "credential \"https://gist.github.com\"".helper = "!gh auth git-credential";
          "credential \"https://github.com\"".helper = "!gh auth git-credential";
          diff = {
            algorithm = "histogram";
            tool = "difftastic";
          };
          difftool.prompt = false;
          "difftool \"difftastic\"".cmd = "difft  \"$LOCAL\" \"$REMOTE\"";
          fetch = {
            fsckobjects = true;
            prune = true;
            prunetags = true;
          };
          "git-extras \"get\"".clone-path = "${config.home.homeDirectory}/.local/state/projects";
          gpg.format = "ssh";
          "gpg \"ssh\"".program = "ssh-keygen";
          init.defaultBranch = "main";
          merge.conflictstyle = "zdiff3";
          pager.difftool = true;
          pull.rebase = true;
          push.autoSetupRemote = true;
          receive.fsckObjects = true;
          rerere.enabled = true;
          tag.sort = "creatordate";
          transfer.fsckobjects = true;
          user.name = "Jared Baur";
          user.email = lib.mkDefault "jaredbaur@fastmail.com";
          user.signingKey = lib.mkDefault "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=";
          commit.gpgSign = lib.mkDefault true;
          "gpg \"ssh\"".defaultKeyCommand = "ssh-add -L";
          "gpg \"ssh\"".allowedSignersFile = lib.mkDefault (
            pkgs.writeText "allowed-signers" ''
              jaredbaur@fastmail.com sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
              jaredbaur@fastmail.com sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
            ''
          );
        };
      };

      nix.package = pkgs.nixVersions.nix_2_35;

      programs.direnv = {
        enable = true;
        nix-direnv = {
          enable = true;
          package = pkgs.nix-direnv.override { nix = config.nix.package; };
        };
      };

      programs.nix-index = {
        enable = true;
        enableBashIntegration = false;
        enableFishIntegration = false;
        enableZshIntegration = false;
        enableNushellIntegration = false;
      };

      programs.bash = {
        enable = true;
        initExtra = ''
          export GOPATH=''${XDG_DATA_HOME:-~/.local/share}/go
          source ${pkgs.bash-sensible}/sensible.bash
          # Undo bash-sensible's magic-space, which performs history expansion
          # while typing. History expansion still happens on enter.
          bind Space:self-insert
          [ -n "$EAT_SHELL_INTEGRATION_DIR" ] && source "$EAT_SHELL_INTEGRATION_DIR/bash"
          if [[ "$INSIDE_EMACS" = 'vterm' ]] \
            && [[ -n ''${EMACS_VTERM_PATH} ]] \
            && [[ -f ''${EMACS_VTERM_PATH}/etc/emacs-vterm-bash.sh ]]; then
          source ''${EMACS_VTERM_PATH}/etc/emacs-vterm-bash.sh
          fi
        '';
      };

      programs.zsh = {
        enable = true;
        initContent = ''
          bindkey -e

          export GOPATH=''${XDG_DATA_HOME:-~/.local/share}/go

          bindkey \^U backward-kill-line

          autoload -Uz vcs_info
          precmd_vcs_info() { vcs_info }
          precmd_newline() { printf "\n" }
          precmd_functions+=(precmd_vcs_info precmd_newline)
          setopt prompt_subst
          zstyle ':vcs_info:*' actionformats '[%b|%a]'
          zstyle ':vcs_info:*' formats '[%b]'
          PROMPT='%B%(?..%F{1}[%?]%f)%F{2}[%n@%m:%2~]''${vcs_info_msg_0_}%#%f%b '
        '';
      };

      xdg.configFile."emacs/early-init.el".text = ''
        ;;; -*- lexical-binding: t -*-
        (setq inhibit-startup-screen t)
      '';

      xdg.configFile."tmux/tmux.conf".text = ''
        set-option -g allow-passthrough on
        set-option -g focus-events on
        set-option -s set-clipboard on
        # Use ctrl+s as prefix
        unbind C-b
        set-option -g prefix C-s
        bind-key C-s send-prefix
      '';

      xdg.configFile."ghostty/config.ghostty".text = ''
        theme = dark:Modus Vivendi,light:Modus Operandi
        keybind = ctrl+enter=unbind
        macos-option-as-alt = true
      '';
    }

    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.ssh.settings."Host *.local".ProxyCommand =
        "${lib.getExe pkgs.ipv6-link-local-ssh-proxy-command} %h %p";

      home.packages = [
        pkgs._caffeine
        pkgs.bpftrace
        pkgs.cntr
        pkgs.hexdiff
        pkgs.inotify-tools
        pkgs.mac-vendor-lookup
        pkgs.pax-utils
        pkgs.poke
        pkgs.strace
      ];
    })
  ];
}
