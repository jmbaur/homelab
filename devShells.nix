inputs: with inputs; nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ] (system:
let
  pkgs = import nixpkgs {
    inherit system;
    overlays = [ self.overlays.default ];
  };
in
{
  ci = pkgs.mkShell {
    buildInputs = with pkgs; [ just jq nix-prefetch-scripts nix-update ];
  };
  default = self.devShells.${system}.ci.overrideAttrs (old: {
    buildInputs = (with pkgs; [
      (terraform.withPlugins (p: with p; [ aws cloudflare http sops ]))
      awscli2
      deploy-rs
      flarectl
      home-manager
      pam_u2f
      sops
      yubikey-manager
    ] ++ old.buildInputs);
    inherit (pre-commit.lib.${system}.run {
      src = ./.;
      hooks = {
        deadnix = { enable = true; excludes = [ "hardware-configuration\\.nix" ]; };
        nixpkgs-fmt = { enable = true; excludes = [ "hardware-configuration\\.nix" ]; };
        shellcheck.enable = true;
        shfmt.enable = true;
        stylua.enable = true;
      };
    }) shellHook;
  });
})
