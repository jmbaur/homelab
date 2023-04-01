{ config, lib, ... }: {
  options.custom.crossCompile.enable = lib.mkEnableOption "cross compile from x86_64-linux";
  config = lib.mkIf config.custom.crossCompile.enable {
    nixpkgs.buildPlatform = "x86_64-linux";
  };
}
