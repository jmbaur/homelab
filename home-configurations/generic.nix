{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    {
      home.packages = with pkgs; [
        (comma.override { nix = config.nix.package; })
        age-plugin-yubikey
        ansifilter
        as-tree
        awscli2
        bat
        carapace
        curl
        difftastic
        dig
        direnv
        fd
        file
        fsrx
        gh
        git
        git-extras
        git-gone
        gnumake
        grex
        gron
        hexyl
        home-manager
        homelab-utils
        htmlq
        htop
        jared-emacs
        jq
        just
        killall
        libarchive
        linux-scripts
        lrzsz
        lsof
        man-pages
        man-pages-posix
        moor
        ncdu
        nix-diff
        nix-tree
        nixos-shell
        nload
        nmap
        nurl
        oils-for-unix
        pciutils
        procs
        pstree
        pwgen
        qemu
        rage
        ripgrep
        sd
        tcpdump
        tea
        tinyxxd
        tio
        tmux-jump
        tokei
        unzip
        usbutils
        watchexec
        zip
      ];

      home.sessionVariables.EDITOR = "emacs";

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*.internal".forwardAgent = true;
        matchBlocks."*.local".forwardAgent = true;
        matchBlocks."i-* mi-*".proxyCommand =
          "${pkgs.runtimeShell} -c \"${lib.getExe pkgs.awscli2} ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'\"";
        matchBlocks."*" = {
          serverAliveInterval = 11;
          controlMaster = "auto";
          controlPath = "/tmp/ssh-%i-%C";
          controlPersist = "30m";
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

      nix.package = pkgs.nixVersions.nix_2_34;

      programs.direnv = {
        enable = true;
        nix-direnv = {
          enable = true;
          package = pkgs.nix-direnv.override { nix = config.nix.package; };
        };
      };

      programs.nix-index.enable = true;

      programs.bash = {
        enable = true;
        initExtra = ''
          export GOPATH=''${XDG_DATA_HOME:-~/.local/share}/go
          source ${pkgs.bash-sensible}/sensible.bash
        '';
      };

      programs.zsh.enable = pkgs.stdenv.hostPlatform.isDarwin;

      xdg.configFile."emacs/init.el".source = ./emacs/init.el;
      xdg.configFile."emacs/early-init.el".source = ./emacs/early-init.el;
    }

    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.ssh.matchBlocks."*.local".proxyCommand =
        "${lib.getExe pkgs.ipv6-link-local-ssh-proxy-command} %h %p";

      home.packages = with pkgs; [
        _caffeine
        bpftrace
        cntr
        hexdiff
        inotify-tools
        mac-vendor-lookup
        pax-utils
        poke
        strace
      ];
    })
  ];
}
