inputs: with inputs;
flake-utils.lib.eachDefaultSystemMap (system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ agenix.overlay self.overlays.default ];
    };
  in
  {
    default = pkgs.mkShell {
      buildInputs = with pkgs; [
        (terraform.withPlugins (p: with p; [ aws cloudflare http ]))
        agenix
        awscli2
        deploy-rs
        flarectl
      ];
      inherit (pre-commit.lib.${system}.run {
        src = ./.;
        hooks.nixpkgs-fmt = {
          enable = true;
          excludes = [ "hardware-configuration\\.nix" ];
        };
      }) shellHook;
    };
  })
