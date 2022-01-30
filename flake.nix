{
  description = "NixOS configurations for the homelab";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gobar.url = "github:jmbaur/gobar";
    gosee.url = "github:jmbaur/gosee";
    neovim.url = "github:neovim/neovim/release-0.6?dir=contrib";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs/nixos-21.11";
    promtop.url = "github:jmbaur/promtop";
    zig.url = "github:arqv/zig-overlay";
  };

  outputs =
    { self
    , deploy-rs
    , flake-utils
    , git-get
    , gobar
    , gosee
    , neovim
    , nixos-hardware
    , nixpkgs
    , nixpkgs-unstable
    , promtop
    , zig
    }@inputs: flake-utils.lib.eachDefaultSystem
      (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ git gnumake ] ++
            pkgs.lib.singleton deploy-rs.defaultPackage.${system};
        };
      })
    //
    rec {
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;

      nixosConfigurations.beetroot = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = with inputs.nixos-hardware.nixosModules; [
          ({ ... }: {
            nixpkgs.overlays = (import ./pkgs/overlays.nix) ++ [
              git-get.overlay
              gobar.overlay
              gosee.overlay
              neovim.overlay
              promtop.overlay
              (final: prev: {
                zig = zig.packages.${prev.system}.master.latest;
              })
            ];
          })
          lenovo-thinkpad-t480
          ./modules
          ./hosts/beetroot/configuration.nix
        ];
      };

      nixosConfigurations.kale = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = with nixos-hardware.nixosModules; [
          common-cpu-amd
          ./modules
          ./hosts/kale/configuration.nix
        ];
      };

      deploy.nodes.kale = {
        hostname = "kale.home.arpa.";
        profiles.system = {
          user = "root";
          sshUser = "deploy";
          path = deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.kale;
        };
      };

      # nixosConfigurations.dev = inputs.nixpkgs.lib.nixosSystem rec {
      #   system = "x86_64-linux";
      #   modules = [
      #     ({ ... }: {
      #       nixpkgs.overlays = [
      #         inputs.git-get.overlay.${system}
      #         inputs.gosee.overlay.${system}
      #         (import ./pkgs/zig.nix)
      #         (import ./pkgs/zls.nix)
      #         (import ./pkgs/nix-direnv.nix)
      #         (self: super: { p = super.callPackage ./pkgs/p.nix { }; })
      #         (self: super: { mosh = inputs.nixpkgs-personal.legacyPackages.${system}.mosh; })
      #       ];
      #     })
      #     ./hosts/dev/configuration.nix
      #     ./modules
      #   ];
      # };
    };




}
