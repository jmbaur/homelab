{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.common;
  isNotContainer = !config.boot.isContainer;
in
{
  options.custom.common.enable = lib.mkEnableOption "common config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    # NOTE: this should be set explicitly if it is actually needed
    system.stateVersion = lib.mkDefault "24.05";

    system.image.id = config.system.nixos.distroId;
    system.image.version = lib.mkDefault "0.0.64";

    # We always build on x86_64-linux.
    #
    # "If it don't cross-compile, it don't go in the config!"
    nixpkgs.buildPlatform = "x86_64-linux";

    environment.enableAllTerminfo = true;

    # moving closer to perlless system
    programs.less.lessopen = lib.mkDefault null;
    environment.defaultPackages = lib.mkDefault [ ];
    documentation.info.enable = lib.mkDefault false;
    programs.command-not-found.enable = false;

    networking.nftables.enable = lib.mkDefault true;

    boot.enableContainers = lib.mkDefault false;
    boot.tmp.cleanOnBoot = lib.mkDefault isNotContainer;

    i18n.defaultLocale = "en_US.UTF-8";
    console.useXkbConfig = true;

    nix = {
      package = pkgs.nixVersions.nix_2_22;
      channel.enable = false; # opt out of nix channels
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [ "@wheel" ];
      };
    };

    # Use the dbus-broker dbus daemon implementation (more performance, yeah?)
    services.dbus.implementation = "broker";

    services.openssh.enable = lib.mkDefault isNotContainer;
  };
}
