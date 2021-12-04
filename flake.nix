{
  description = "NixOS configurations for homelab";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-stable-small.url = "nixpkgs/nixos-21.11-small";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    zig.url = "github:arqv/zig-overlay?rev=080ef681b4ab24f96096ca5d7672d5336006fa65";
    gosee.url = "github:jmbaur/gosee";
    git-get.url = "github:jmbaur/git-get";
  };

  outputs = inputs:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        inherit system; overlays = [
        (self: super: {
          fdroidcl = super.callPackage ./pkgs/fdroidcl.nix { };
          git-get = inputs.git-get.defaultPackage.${system};
          gosee = inputs.gosee.defaultPackage.${system};
          p = super.callPackage ./pkgs/p.nix { };
          zig = inputs.zig.packages.${system}.master.latest;
        })
        (import ./pkgs/neovim.nix)
        (import ./pkgs/nix-direnv.nix)
        (import ./pkgs/tmux.nix)
        (import ./pkgs/zls.nix)
      ];
      };
      src = builtins.path { path = ./.; };
    in
    rec {
      devShell.${system} = pkgs.mkShell {
        buildInputs = with pkgs;[ git gnumake ];
      };
      checks.${system}.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        inherit src;
        hooks.nixpkgs-fmt.enable = true;
      };
      packages.${system}.all =
        let
          myProfile = pkgs.writeText "my-profile" ''
            export GIT_CONFIG_GLOBAL=${pkgs.writeText "gitconfig" "${builtins.readFile ./config/git/gitconfig}"}

            export SUMNEKO_ROOT_PATH=${pkgs.sumneko-lua-language-server}

            eval "$(${pkgs.direnv}/bin/direnv hook bash)"

            if [ ! -f $HOME/.direnvrc ]; then
              printf "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc" > $HOME/.direnvrc
            fi
          '';
        in
        pkgs.buildEnv {
          name = "all";
          paths = with pkgs; [
            (runCommand "profile" { } ''
              mkdir -p $out/etc/profile.d
              cp ${myProfile} $out/etc/profile.d/my-profile.sh
            '')
            age
            awscli2
            bat
            black
            buildah
            curl
            direnv
            dust
            efm-langserver
            exa
            fd
            fdroidcl
            ffmpeg-full
            fzf
            geteltorito
            gh
            gimp
            git
            git-get
            gnupg
            go
            goimports
            gopls
            gosee
            gotop
            grex
            gron
            htmlq
            jq
            keybase
            librespeed-cli
            luaformatter
            mob
            mosh
            mpv
            neovim
            nix-direnv
            nix-prefetch-docker
            nix-tree
            nixUnstable
            nixopsUnstable
            nixos-generators
            nixpkgs-fmt
            nnn
            nodePackages.prettier
            nodePackages.typescript
            nodePackages.typescript-language-server
            nodejs
            nushell
            nvme-cli
            openssl
            p
            pass
            pass-git-helper
            patchelf
            picocom
            plan9port
            pwgen
            pyright
            python3
            renameutils
            ripgrep
            rtorrent
            rust-analyzer
            sd
            shfmt
            skopeo
            sl
            speedtest-cli
            stow
            sumneko-lua-language-server
            tailscale
            tcpdump
            tea
            tealdeer
            tig
            tmux
            tokei
            trash-cli
            tree-sitter
            unzip
            usbutils
            wget
            wl-clipboard
            xdg-user-dirs
            xdg-utils
            xsv
            ydiff
            yq
            yubikey-personalization
            zig
            zip
            zls
            zoxide
          ];
        };
      defaultPackage.${system} = packages.${system}.all;
      nixosConfigurations.beetroot = with inputs.nixos-hardware.nixosModules; inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          common-pc-ssd
          common-cpu-amd
          common-gpu-amd
          common-pc-laptop-acpi_call
          lenovo-thinkpad
          ./hosts/beetroot/configuration.nix
        ];
      };

      nixopsConfigurations.default = with inputs.nixos-hardware.nixosModules; {
        nixpkgs = inputs.nixpkgs-stable-small;
        network = {
          description = "homelab";
          enableRollback = true;
          storage.legacy = { };
        };
        broccoli = { config, pkgs, ... }: {
          deployment.targetHost = "broccoli.home.arpa.";
          imports = [
            common-pc-ssd
            common-cpu-intel
            ./lib/nixops.nix
            ./hosts/broccoli/configuration.nix
          ];
        };
        rhubarb = { config, pkgs, ... }: {
          deployment.targetHost = "rhubarb.home.arpa.";
          imports = [
            raspberry-pi-4
            ./lib/nixops.nix
            ./hosts/rhubarb/configuration.nix
          ];
        };
        asparagus = { config, pkgs, ... }: {
          deployment.targetHost = "asparagus.home.arpa.";
          imports = [
            common-pc-ssd
            common-cpu-intel
            ./lib/nixops.nix
            ./hosts/asparagus/configuration.nix
          ];
        };
      };
    };




}
