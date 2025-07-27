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
        abduco
        age-plugin-yubikey
        ansifilter
        as-tree
        bash-language-server
        bat
        cachix
        carapace
        comma
        copy
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
        htmlq
        htop-vim
        jared-neovim
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
        moar
        ncdu
        nix-diff
        nix-output-monitor
        nix-tree
        nixos-shell
        nload
        nmap
        nurl
        oils-for-unix
        pb
        pciutils
        pomo
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
        wip
        zip
      ];

      home.sessionVariables.EDITOR = "nvim";

      programs.ssh = {
        enable = true;
        serverAliveInterval = 11;
        controlMaster = "auto";
        controlPath = "/tmp/ssh-%i-%C";
        controlPersist = "30m";
        matchBlocks."*.internal".forwardAgent = true;
        matchBlocks."*.local".forwardAgent = true;
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
          "credential \"https://gist.github.com\"".helper = "gh auth git-credential";
          "credential \"https://github.com\"".helper = "gh auth git-credential";
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
          "url \"git+ssh://git@codeberg.org/\"".pushInsteadOf = "https://codeberg.org/";
          "url \"git+ssh://git@github.com/\"".pushInsteadOf = "https://github.com/";
          "url \"git+ssh://git@gitlab.com/\"".pushInsteadOf = "https://gitlab.com/";
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

      nix = {
        package = pkgs.nixVersions.nix_2_30;
        settings.warn-dirty = false;
      };

      programs.direnv.enable = true;

      programs.nix-index.enable = true;

      programs.zsh = {
        enable = true;
        initContent = ''
          bindkey -e
          alias j=tmux-jump
          bindkey \^U backward-kill-line
        '';
      };

      programs.bash = {
        enable = true;
        initExtra = ''
          export GOPATH=''${XDG_DATA_HOME:-~/.local/share}/go

          alias j=tmux-jump

          function remove-ssh-connections() {
            pids=$(fd --regex 'ssh-[0-9]+-[a-f0-9]{40}' /tmp \
              --exec lsfd --filter "NAME =~ \"state=listen path={}\"" --output PID --noheadings \;)

            if [[ -n $pids ]]; then
              kill $pids
            fi
          }

          source ${pkgs.bash-sensible}/sensible.bash

          source ${config.programs.git.package}/share/bash-completion/completions/git-prompt.sh

          __my_ps1() {
            # This must be first so we capture the exit status of the last command.
            local status=$?

            local prompt_color="1;31m"
            ((UID)) && prompt_color="1;32m"

            # Print OSC0 to set the terminal title and OSC7 to set the terminal
            # working directory. Add a newline to give the prompt some extra space.
            local begin="\033]0;\u@\h:\w\007\033]7;file://$HOSTNAME$PWD\007\n"

            # Prefix the prompt with the last exit code if it was non-zero.
            if [[ $status -ne 0 ]]; then
            	begin="$begin\[\033[1;31m\][$status]\[\033[0m\]"
            fi

            # Add the actual prompt.
            begin="$begin\[\033[$prompt_color\][\u@\h:\w]"

            __git_ps1 "$begin" "\\\$\[\033[0m\] " "[%s]"
          }

          if [ "$TERM" == "dumb" ]; then
            unset PROMPT_COMMAND
            PS1='$ '
          else
            # Inspired from direnv's way of prepending stuff to PROMPT_COMMAND (see output
            # of `direnv hook bash`).
            if [[ ";''${PROMPT_COMMAND[*]:-};" != *";__my_ps1;"* ]]; then
              if [[ "$(declare -p PROMPT_COMMAND 2>&1)" == "declare -a"* ]]; then
                PROMPT_COMMAND=(__my_ps1 "''${PROMPT_COMMAND[@]}")
              else
                PROMPT_COMMAND="__my_ps1''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
              fi
            fi
          fi
        '';
      };

      programs.tmux = {
        enable = true;
        aggressiveResize = true;
        baseIndex = 1;
        clock24 = true;
        escapeTime = 10;
        historyLimit = 50000;
        keyMode = "vi";
        terminal = "tmux-256color";
        plugins = [
          pkgs.tmuxPlugins.fingers
          pkgs.tmuxPlugins.logging
        ];
        extraConfig = ''
          unbind C-b
          set -g prefix C-s
          bind-key -N "Send the prefix key through to the application" C-s send-prefix

          set-option -as terminal-features ",alacritty:RGB"
          set-option -as terminal-features ",foot:RGB"
          set-option -as terminal-features ",rio:RGB"
          set-option -as terminal-features ",wezterm:RGB"
          set-option -as terminal-features ",xterm-256color:RGB"
          set-option -as terminal-features ",xterm-kitty:RGB"
          set-option -g allow-passthrough on
          set-option -g automatic-rename on
          set-option -g default-command $SHELL
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

          bind-key -N "Kill the current pane" x kill-pane
          bind-key -N "Kill the current window" & kill-window
          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi y send-keys -X copy-selection
          bind-key ESCAPE copy-mode
          bind-key J command-prompt -p "join pane from:"  "join-pane -h -s '%%'"
          bind-key j display-popup -EE tmux-jump
        '';
      };
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
        ipv6-link-local-ssh-proxy-command
        nixos-kexec
        pax-utils
        poke
        strace-with-colors
      ];
    })
  ];
}
