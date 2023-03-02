inputs: inputs.nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ] (system:
let
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ inputs.self.overlays.default ];
  };
in
{
  ci = pkgs.mkShell {
    buildInputs = with pkgs; [ just jq nix-prefetch-scripts nix-update ];
  };
  setup = pkgs.mkShell {
    buildInputs = with pkgs; [ just pam_u2f yubikey-manager teensy-loader-cli ];
  };
  deploy = pkgs.mkShell {
    buildInputs = (with pkgs; [
      (terraform.withPlugins (p: with p; [ aws cloudflare http sops ]))
      awscli2
      deploy-rs
      flarectl
      just
    ]);
  };
  default = pkgs.mkShell {
    buildInputs = (with pkgs; [ bashInteractive just sops nix-update ]);
    inherit (inputs.pre-commit.lib.${system}.run {
      src = ./.;
      hooks = {
        deadnix = { enable = true; excludes = [ "hardware-configuration\\.nix" ]; };
        nixpkgs-fmt = { enable = true; excludes = [ "hardware-configuration\\.nix" ]; };
        revive.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
        stylua.enable = true;
      };
    }) shellHook;
  };
})
