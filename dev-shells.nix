inputs: inputs.nixpkgs.lib.mapAttrs
  (system: pkgs: {
    ci = pkgs.mkShell {
      buildInputs = with pkgs; [ ansifilter just jq nix-prefetch-scripts nix-update ];
    };
    default = pkgs.mkShell {
      buildInputs = (with pkgs; [ bashInteractive just sops nix-update nix-prefetch-scripts jq ]);
      inherit (inputs.pre-commit.lib.${system}.run {
        src = ./.;
        hooks = {
          deadnix.enable = true;
          revive.enable = true;
          shellcheck.enable = true;
          shfmt.enable = true;
        };
      }) shellHook;
    };
  })
  inputs.self.legacyPackages
