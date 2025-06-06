{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.dev;
in
{
  options.custom.dev.enable = lib.mkEnableOption "dev setup";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        documentation.enable = true;
        documentation.doc.enable = true;
        documentation.info.enable = true;
        documentation.man.enable = true;
        documentation.nixos.enable = true;

        services.scx = {
          enable = lib.mkDefault true;
          scheduler = "scx_bpfland";
        };

        programs.ssh.startAgent = lib.mkDefault true;
        programs.gnupg.agent.enable = lib.mkDefault true;
        services.pcscd.enable = config.custom.desktop.enable;

        programs.adb.enable = lib.mkDefault true;

        boot.binfmt = {
          # Make sure builder isn't masquerading as being
          # able to do native builds for non-native
          # architectures.
          addEmulatedSystemsToNixSandbox = false;

          # Makes chroot/sandbox environments of
          # different architectures work.
          preferStaticEmulators = true;

          emulatedSystems =
            lib.optionals pkgs.stdenv.hostPlatform.isAarch64 [
              # TODO(jared): pkgsStatic.qemu-user doesn't build right now
              # "riscv32-linux"
              # "riscv64-linux"
              # "i686-linux"
              # "x86_64-linux"
            ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
              "riscv32-linux"
              "riscv64-linux"
              "armv7l-linux"
              "aarch64-linux"
            ];
        };
      }
      {
        environment.systemPackages = with pkgs; [
          _caffeine
          abduco
          age-plugin-yubikey
          ansifilter
          as-tree
          bash-language-server
          bat
          binary-diff
          bpftrace
          cachix
          carapace
          clang-tools
          cntr
          comma
          copy
          curl
          difftastic
          dig
          direnv
          fd
          file
          fsrx
          fzf
          gh
          git
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
          ipv6-link-local-ssh-proxy-command
          jq
          just
          killall
          libarchive
          linux-scripts
          lrzsz
          lsof
          lua-language-server
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
          tinyxxd
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

        programs.neovim = {
          enable = true;
          defaultEditor = true;
          withRuby = false;
          vimAlias = true;
          configure = {
            customRC = "set exrc";
            packages.pack.start =
              [
                (pkgs.vimUtils.buildVimPlugin {
                  name = "jared-neovim-config";
                  src = ./nvim;
                })
              ]
              ++ (with pkgs.vimPlugins; [
                bpftrace-vim
                fzf-lua
                nvim-treesitter.withAllGrammars
                vim-dispatch
                vim-eunuch
                vim-fugitive
                vim-rsi
                vim-surround
                vim-vinegar
              ]);
          };
        };

        # TODO(jared): could probably go in common
        programs.ssh.extraConfig = ''
          Host *.internal
            ForwardAgent yes

          Host *.local
            ForwardAgent yes
            ProxyCommand ipv6-link-local-ssh-proxy-command %h %p

          Host *
            ServerAliveInterval 11
            ControlMaster auto
            ControlPath /tmp/ssh-%i-%C
            ControlPersist 30m
        '';

        programs.git = {
          enable = true;
          config = {
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
            "git-extras \"get\"".clone-path = "/var/lib/projects";
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

        systemd.tmpfiles.settings."10-projects"."/var/lib/projects".d = {
          group = config.users.groups.wheel.name;
          mode = "0770";
        };

        programs.direnv.enable = true;

        programs.nix-index.enable = true;

        programs.bash = {
          promptInit = "";

          interactiveShellInit = ''
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
    ]
  );
}
