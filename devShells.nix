inputs: with inputs;
flake-utils.lib.eachDefaultSystemMap (system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ agenix.overlay ];
    };
  in
  {
    default = pkgs.mkShell {
      buildInputs = with pkgs; [
        (terraform.withPlugins (p: [ p.cloudflare ]))
        agenix
        deploy-rs
      ];
      inherit (pre-commit.lib.${system}.run {
        src = ./.;
        hooks.nixpkgs-fmt.enable = true;
      }) shellHook;
    };
  })
