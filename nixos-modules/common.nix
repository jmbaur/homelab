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
    system.stateVersion = lib.mkDefault "24.11";

    system.image.id = config.system.nixos.distroId;

    # We always build on x86_64-linux.
    #
    # "If it don't cross-compile, it don't go in the config!"
    nixpkgs.buildPlatform = "x86_64-linux";

    # CapsLock is terrible
    services.xserver.xkb.options = lib.mkDefault "ctrl:nocaps";

    environment.enableAllTerminfo = true;

    programs.nano.enable = false;
    programs.vim.defaultEditor = true;

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

    # no need for mutable users
    users.mutableUsers = lib.mkDefault false;

    nix = {
      package = pkgs.nixVersions.nix_2_23;
      channel.enable = false; # opt out of nix channels
      settings.trusted-users = [
        "root"
        "@wheel"
      ];
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    # Provide a sane default value so that commands don't outright fail on an
    # otherwise unconfigured machine.
    environment.sessionVariables.NIX_PATH = lib.mkIf config.nix.enable (
      lib.mkDefault "nixpkgs=https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz"
    );

    # Use the dbus-broker dbus daemon implementation (more performance, yeah?)
    services.dbus.implementation = "broker";

    services.openssh = {
      enable = lib.mkDefault isNotContainer;
      settings.PasswordAuthentication = false;
    };
  };
}
