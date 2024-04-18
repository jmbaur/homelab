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
    system.image.version = "0.0.45";

    # We always build on x86_64-linux.
    #
    # "If it don't cross-compile, it don't go in the config!"
    nixpkgs.buildPlatform = "x86_64-linux";

    environment.defaultPackages = [ ];

    programs.less.lessopen = lib.mkIf (pkgs.stdenv.hostPlatform != pkgs.stdenv.buildPlatform) null;

    documentation.enable = lib.mkDefault false;
    documentation.doc.enable = lib.mkDefault false;
    documentation.info.enable = lib.mkDefault false;
    documentation.man.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;

    programs.command-not-found.enable = false;

    networking.nftables.enable = lib.mkDefault true;

    boot.enableContainers = lib.mkDefault false;
    boot.tmp.cleanOnBoot = lib.mkDefault isNotContainer;

    i18n.defaultLocale = "en_US.UTF-8";
    console.useXkbConfig = true;

    nix = {
      package = pkgs.nixVersions.nix_2_21;
      channel.enable = false; # opt out of nix channels
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [ "@wheel" ];
      };
    };

    services.openssh = lib.mkIf isNotContainer {
      enable = true;
      settings = {
        # use more secure defaults
        PermitRootLogin = lib.mkDefault "prohibit-password";
        PasswordAuthentication = lib.mkDefault false;
      };
    };
  };
}
