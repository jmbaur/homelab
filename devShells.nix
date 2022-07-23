inputs: with inputs;
flake-utils.lib.eachDefaultSystemMap (system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ deploy-rs.overlay agenix.overlay ];
    };
  in
  {
    default = pkgs.mkShell {
      buildInputs = [
        (pkgs.terraform.withPlugins (p: [ p.cloudflare ]))
        pkgs.agenix
        pkgs.deploy-rs.deploy-rs
      ];
      inherit (pre-commit.lib.${system}.run {
        src = builtins.path { path = ./.; };
        hooks.nixpkgs-fmt.enable = true;
      }) shellHook;
    };
  })
