{ config, lib, pkgs, ... }: {
  options.custom.crossCompile.enable = lib.mkEnableOption "cross compile from x86_64-linux";

  config = lib.mkIf config.custom.crossCompile.enable {
    assertions = [{
      assertion = pkgs.stdenv.hostPlatform.system != pkgs.stdenv.buildPlatform.system;
      message = "Cannot enable cross-compile while hostPlatform == buildPlatform";
    }];

    nixpkgs.buildPlatform = "x86_64-linux";
  };
}
