{
  description = "NixOS configurations for the homelab";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gosee.url = "github:jmbaur/gosee";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs-personal.url = "github:jmbaur/nixpkgs/31aa6abb9727736e2f3be2e8dea5d0e38f749416";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    promtop.url = "github:jmbaur/promtop";
    zig.url = "github:arqv/zig-overlay";
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem
    (system:
      let pkgs = inputs.nixpkgs.legacyPackages.${system}; in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ git gnumake ] ++
            pkgs.lib.singleton inputs.deploy-rs.defaultPackage.${system};
        };
        packages.p = pkgs.callPackage ./pkgs/p.nix { };
      })
  //
  rec {
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deploy) inputs.deploy-rs.lib;

    nixosConfigurations.beetroot = inputs.nixpkgs-unstable.lib.nixosSystem {
      system = "x86_64-linux";
      modules = with inputs.nixos-hardware.nixosModules; [
        lenovo-thinkpad-t480
        ./modules
        ./lib/common.nix
        ./hosts/beetroot/configuration.nix
      ];
    };

    nixosConfigurations.kale = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = with inputs.nixos-hardware.nixosModules; [
        common-cpu-amd
        ./lib/common.nix
        ./lib/deploy.nix
        ./hosts/kale/configuration.nix
      ];
    };

    deploy.nodes.kale = {
      hostname = "kale.home.arpa.";
      profiles.system = {
        user = "root";
        sshUser = "deploy";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.kale;
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
