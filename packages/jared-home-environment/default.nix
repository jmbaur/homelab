{
  buildEnv,
  formats,
  jq,
  lib,
  pkgs,
  runCommand,
  substituteAll,
  writeShellApplication,
  writeText,

  extraFiles ? { },
  extraPackages ? [ ],
  sshIncludes ? [ ],
  gitIncludes ? [
    (substituteAll {
      src = ./personal.gitconfig;
      allowedSignersFile = writeText "allowed-signers" ''
        jaredbaur@fastmail.com sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
        jaredbaur@fastmail.com sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
      '';
    })
  ],
}:

let
  manifest = (formats.json { }).generate "manifest.json" (
    {
      ".gnupg/scdaemon.conf" = writeText "scdaemon.conf" ''
        disable-ccid
      '';

      ".gnupg/gpg.conf" = writeText "gpg.conf" ''
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

      ".config/nix/nix.conf" = writeText "nix.conf" ''
        experimental-features = nix-command flakes
      '';

      ".sqliterc" = writeText "sqliterc" ''
        .headers ON
        .mode columns
      '';

      ".config/fd/ignore" = writeText "fd-ignore" ''
        .git
      '';

      ".bash_profile" = writeText "bash-profile" ''
        source $HOME/.bashrc
      '';

      ".bashrc" = substituteAll {
        name = "bashrc";
        src = ./bashrc.in;
        bashSensible = pkgs.bash-sensible;
        nixIndex = pkgs.nix-index;
        git = pkgs.git;
      };

      ".config/direnv/lib/nix-direnv.sh" = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";

      ".ssh/config" = substituteAll {
        name = "sshconfig";
        src = ./ssh-config.in;
        extraConfig = lib.concatLines (map (include: "Include ${include}") sshIncludes);
      };

      ".config/git/ignore" = ./gitignore;
      ".config/git/config" = substituteAll {
        name = "gitconfig";
        src = ./gitconfig.in;
        extraConfig = ''
          [include]
          ${lib.concatLines (map (include: "  path = ${include}") gitIncludes)}
        '';
      };

      ".config/tmux/tmux.conf" = substituteAll {
        name = "tmux.conf";
        src = ./tmux.conf.in;
        tmuxLogging = pkgs.tmuxPlugins.logging;
        tmuxFingers = pkgs.tmuxPlugins.fingers;
      };

      ".config/vim" = runCommand "vim-config" { } ''
        cp -r ${./vim} $out; chmod +w $out
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
                fzf-vim
                lsp
                vim-commentary
                vim-dir
                vim-dispatch
                vim-eunuch
                vim-fugitive
                vim-repeat
                vim-rsi
                vim-sensible
                vim-surround
                vim-unimpaired
              ]
            )
        )}
      '';
    }
    // extraFiles
  );

  environment = buildEnv {
    name = "jared-home-environment";

    inherit manifest;

    paths =
      (with pkgs; [
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
      ])
      ++ extraPackages;
  };
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
          echo "Will not clobber existing file at $destination"
        else
          if [[ $(readlink --canonicalize-existing "$destination") == "$source" ]]; then
            exit 0 # only exits this subshell
          fi
          ln --verbose --symbolic --force "$source" "$destination"
        fi
      )
    done
  '';
}
