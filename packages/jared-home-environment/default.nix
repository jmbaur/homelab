{
  buildEnv,
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
  environment = buildEnv {
    name = "jared-home-environment";
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

  files = {
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
      src = ./bashrc.in;
      bashSensible = pkgs.bash-sensible;
      nixIndex = pkgs.nix-index;
      git = pkgs.git;
    };

    ".config/direnv/lib/nix-direnv.sh" = writeText "nix-direnv.sh" ''
      ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
    '';

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
  } // extraFiles;
in

# TODO(jared): Remove old files not in new environment
writeShellApplication {
  name = "${environment.name}-activate";
  text = ''
    nix profile remove ${environment.name}
    nix profile install ${environment}

    ${lib.concatLines (
      lib.mapAttrsToList (destination: content: ''
        (
          destination="$HOME/${destination}"
          mkdir -p "$(dirname "$destination")"
          if [[ -L "$destination" ]]; then
            rm -f "$destination"
            ln -sf ${content} "$destination"
          elif [[ -e "$destination" ]]; then
            echo "Will not clobber existing file at $destination"
          fi
        )
      '') files
    )}
  '';
}
