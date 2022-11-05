{ lib, config, pkgs, inputs, ... }:
let
  cfg = config.custom.cross-compiled;
in
{
  options.custom.cross-compiled = {
    aarch64-linux.enable = lib.mkEnableOption "x86_64-linux build to aarch64-linux host";
    armv7l-linux.enable = lib.mkEnableOption "x86_64-linux build to armv7l-linux host";
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.aarch64-linux.enable {
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
    })
    (lib.mkIf cfg.armv7l-linux.enable {
      nixpkgs.overlays = lib.mkAfter [
        (_: _:
          let p = import pkgs.path { localSystem = "x86_64-linux"; }; in {
            inherit (p.pkgsCross.armv7l-hf-multiplatform)
              ubootClearfog
              ;
          })
      ];
    })
  ];

}
