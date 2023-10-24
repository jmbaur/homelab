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
  default = pkgs.mkShell {
    buildInputs = (with pkgs; [ bashInteractive just sops ]);
    inherit (inputs.pre-commit.lib.${system}.run {
      src = ./.;
      hooks = {
        deadnix.enable = true;
        nixpkgs-fmt.enable = true;
        revive.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
      };
    }) shellHook;
  };
})
