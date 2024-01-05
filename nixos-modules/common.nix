{ config, lib, ... }:
let
  cfg = config.custom.common;
  isNotContainer = !config.boot.isContainer;
in
{
  options.custom.common.enable = lib.mkEnableOption "common config" // { default = true; };

  config = lib.mkIf cfg.enable {
    # NOTE: this should be set explicitly if it is actually needed
    system.stateVersion = lib.mkDefault "24.05";

    custom.image.version = lib.head (builtins.match "(.*)[[:space:]]" (builtins.readFile ../.version));

    # We build on x86_64-linux.
    #
    # NOTE: We cannot simply set buildPlatform to "x86_64-linux" since the
    # applied option is passed to lib.systems.elaborate, and for some reason
    # (lib.systems.elaborate "x86_64-linux") != (lib.systems.elaborate
    # "x86_64-linux"), which is determined by nixpkgs if the nixos system needs
    # to be cross-compiled. See https://github.com/NixOS/nixpkgs/issues/278001.
    nixpkgs.buildPlatform = if (!config.nixpkgs.hostPlatform.isx86_64) then "x86_64-linux" else config.nixpkgs.hostPlatform;

    environment.defaultPackages = [ ];

    documentation.enable = lib.mkDefault false;
    documentation.doc.enable = lib.mkDefault false;
    documentation.info.enable = lib.mkDefault false;
    documentation.man.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;

    programs.command-not-found.enable = false;

    security.sudo.extraRules = [{ groups = [ "wheel" ]; commands = [{ command = "/run/current-system/sw/bin/networkctl"; options = [ "NOPASSWD" ]; }]; }];

    networking.nftables.enable = lib.mkDefault true;

    boot.enableContainers = lib.mkDefault false;
    boot.tmp.cleanOnBoot = lib.mkDefault isNotContainer;

    i18n.defaultLocale = "en_US.UTF-8";
    console.useXkbConfig = true;

    nix = {
      channel.enable = false; # opt out of nix channels
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
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
