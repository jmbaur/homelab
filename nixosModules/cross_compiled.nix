{ lib, config, pkgs, inputs, ... }: {
  options.custom.cross-compiled.enable = lib.mkEnableOption "x86_64-linux build to aarch64-linux host";
  config = lib.mkIf config.custom.cross-compiled.enable {
    nixpkgs.overlays = lib.mkAfter [
      (_: _:
        let
          p = import pkgs.path {
            localSystem = "x86_64-linux";
            overlays = [
              inputs.ipwatch.overlays.default
              inputs.runner-nix.overlays.default
              inputs.self.overlays.default
              inputs.webauthn-tiny.overlays.default
            ];
          };
        in
        {
          inherit (p.pkgsCross.aarch64-multiplatform)
            ipwatch
            linux_cn913x
            runner-nix
            webauthn-tiny
            ;
        })
    ];
  };
}

