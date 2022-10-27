inputs: with inputs;
flake-utils.lib.eachDefaultSystemMap (system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        nixos-configs.overlays.default
        self.overlays.default
      ];
    };
  in
  {
    ci = pkgs.mkShell {
      buildInputs = with pkgs; [ just jq ];
    };
    default = pkgs.mkShell {
      buildInputs = with pkgs; [
        (terraform.withPlugins (p: with p; [ aws cloudflare http sops ]))
        awscli2
        deploy-rs
        flarectl
        just
        pam_u2f
        sops
        yubikey-manager
      ];
      inherit (pre-commit.lib.${system}.run {
        src = ./.;
        hooks = {
          nixpkgs-fmt = { enable = true; excludes = [ "hardware-configuration\\.nix" ]; };
          deadnix = { enable = true; excludes = [ "hardware-configuration\\.nix" ]; };
        };
      }) shellHook;
    };
  })
