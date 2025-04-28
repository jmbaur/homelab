{
  jq,
  lib,
  pkgs,
  writeShellApplication,

  extraModules ? [ ],
}:

let
  baseModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      gitIncludes = lib.mkDefault [
        (pkgs.replaceVars ./personal.gitconfig {
          signingKey = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=";
          allowedSignersFile = pkgs.writeText "allowed-signers" ''
            jaredbaur@fastmail.com sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
            jaredbaur@fastmail.com sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
          '';
        })
      ];

      files = {
        ".gnupg/scdaemon.conf" = pkgs.writeText "scdaemon.conf" ''
          disable-ccid
        '';

        ".gnupg/gpg.conf" = pkgs.writeText "gpg.conf" ''
          cert-digest-algo SHA512
          charset utf-8
          default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
          fixed-list-mode
          keyid-format 0xlong
          list-options show-uid-validity
          no-comments
          no-emit-version
          no-symkey-cache
          personal-cipher-preferences AES256 AES192 AES
          personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
          personal-digest-preferences SHA512 SHA384 SHA256
          require-cross-certification
          s2k-cipher-algo AES256
          s2k-digest-algo SHA512
          use-agent
          verify-options show-uid-validity
          with-fingerprint
        '';

        ".config/nix/nix.conf" = pkgs.writeText "nix.conf" ''
          experimental-features = nix-command flakes
        '';

        ".sqliterc" = pkgs.writeText "sqliterc" ''
          .headers ON
          .mode columns
        '';

        ".config/fd/ignore" = pkgs.writeText "fd-ignore" ''
          .git
        '';

        # Source bashrc if we are in an interactive shell
        ".bash_profile" = pkgs.writeText "bash-profile" ''
          if [[ $- == *i* ]] && [[ -f $HOME/.bashrc ]]; then
            source $HOME/.bashrc
          fi
        '';

        ".bashrc" = pkgs.replaceVars ./bashrc.in {
          bashSensible = pkgs.bash-sensible;
          nixIndex = pkgs.nix-index;
          git = pkgs.git;
        };

        ".config/direnv/lib/nix-direnv.sh" = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";

        ".ssh/config" = pkgs.replaceVars ./ssh-config.in {
          extraConfig = lib.concatLines (map (include: "Include ${include}") config.sshIncludes);
        };

        ".config/git/ignore" = ./gitignore;
        ".config/git/config" = pkgs.replaceVars ./gitconfig.in {
          extraConfig = ''
            [include]
            ${lib.concatLines (map (include: "  path = ${include}") config.gitIncludes)}
          '';
        };

        ".config/tmux/tmux.conf" = pkgs.replaceVars ./tmux.conf.in {
          tmuxLogging = pkgs.tmuxPlugins.logging;
          tmuxFingers = pkgs.tmuxPlugins.fingers;
        };

        ".config/emacs" = ./emacs;

        ".config/nvim" = pkgs.runCommand "nvim-config" { } ''
          cp -r ${./nvim} $out; chmod +w $out
          mkdir -p $out/pack/jared/start
          ${lib.concatLines (
            map
              (plugin: ''
                cp -r ${plugin} $out/pack/jared/start/${plugin.name}
              '')
              (
                with pkgs.vimPlugins;
                [
                  bpftrace-vim
                  fzf-lua
                  nvim-qwahl
                  vim-dispatch
                  vim-eunuch
                  vim-fugitive
                  vim-rsi
                  vim-surround
                  vim-vinegar
                ]
              )
          )}
        '';
      };

      packages =
        [
          (pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
            vimAlias = true;
            withNodeJs = false;
            withPerl = false;
            withPython3 = false;
            withRuby = false;
            wrapRc = false;
          })
        ]
        ++ (with pkgs; [
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
          inotify-tools
          ipv6-link-local-ssh-proxy-command
          jared-emacs
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
          tmux
          tmux-jump
          tokei
          ttags
          unzip
          usbutils
          watchexec
          wip
          zip
          zls
        ]);
    };

  eval = lib.evalModules {
    specialArgs = { inherit pkgs; };
    modules = [
      (
        { config, lib, ... }:
        {
          options = {
            files = lib.mkOption {
              type = lib.types.attrsOf lib.types.path;
              default = { };
            };

            packages = lib.mkOption { };

            gitIncludes = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
            };

            sshIncludes = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
            };

            environment = lib.mkOption {
              readOnly = true;
              type = lib.types.package;
            };
          };

          config.environment = pkgs.buildEnv {
            name = "jared-home-environment";
            manifest = (pkgs.formats.json { }).generate "manifest.json" config.files;
            paths = config.packages;
          };
        }
      )
      baseModule
    ] ++ extraModules;
  };

  inherit (eval.config) environment;
in
writeShellApplication {
  name = "${environment.name}-activate";
  runtimeInputs = [ jq ];
  text = ''
    existing=$(jq --raw-output '.elements | to_entries[] | select(.key == "${environment.name}") | .value.storePaths[]' < <(nix profile list --json))

    if [[ -n $existing ]]; then
      if [[ -e $existing/manifest ]]; then
        mapfile -t env_diff < <(cat "$existing/manifest" ${environment}/manifest | jq --raw-output --slurp '(.[0] | keys) - (.[1] | keys) | .[]')
        for path in "''${env_diff[@]}"; do
          rm --verbose --force "$HOME/$path"
        done
      fi

      nix profile remove ${environment.name} 2>/dev/null
    fi

    nix profile install ${environment}

    mapfile -t entries < <(jq --raw-output 'to_entries | map("\(.key) \(.value)") | .[]' < ${environment}/manifest)

    for line in "''${entries[@]}"; do
      (
        IFS=' ' read -r -a elements <<< "$line"
        destination="$HOME/''${elements[0]}"
        source="''${elements[1]}"
        mkdir --parents "$(dirname "$destination")"
        if [[ -e "$destination" ]] && [[ ! -L "$destination" ]]; then
          echo "will not clobber existing file at $destination"
        else
          if [[ $(readlink --canonicalize-existing "$destination") == "$source" ]]; then
            exit 0 # only exits this subshell
          fi
          ln --verbose --symbolic --force --no-dereference "$source" "$destination"
        fi
      )
    done
  '';
}
