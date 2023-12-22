{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.custom.common;
  isNotContainer = !config.boot.isContainer;
in
{
  options.custom.common.enable = lib.mkEnableOption "common config" // { default = true; };

  config = lib.mkIf cfg.enable {
    # NOTE: this should be set explicitly if it is actually needed
    system.stateVersion = lib.mkDefault "24.05";

    environment.defaultPackages = [ ];
    environment.systemPackages = lib.optional config.nix.enable pkgs.nixos-kexec;

    programs.vim.defaultEditor = true;

    security.sudo.extraRules = [{ groups = [ "wheel" ]; commands = [{ command = "/run/current-system/sw/bin/networkctl"; options = [ "NOPASSWD" ]; }]; }];

    networking.nftables.enable = lib.mkDefault true;

    boot.tmp.cleanOnBoot = lib.mkDefault isNotContainer;
    boot.loader.grub.configurationLimit = lib.mkDefault 50;
    boot.loader.systemd-boot.configurationLimit = lib.mkDefault 50;

    i18n.defaultLocale = "en_US.UTF-8";
    console.useXkbConfig = true;

    # 2.16 has a fix for ssh control master when nix-copy'ing
    nix.package = if lib.versionAtLeast pkgs.nix.version "2.16" then pkgs.nix else pkgs.nixVersions.nix_2_16;

    # pin a local system's registry for nixpkgs
    nix.registry.nixpkgs.flake = inputs.nixpkgs;

    nix = {
      channel.enable = false; # opt out of nix channels
      nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
      settings = {
        nix-path = config.nix.nixPath;
        experimental-features = [ "nix-command" "flakes" "repl-flake" ];
        trusted-users = [ "@wheel" ];
      };
      gc = lib.mkIf (config.nix.enable && isNotContainer) {
        automatic = lib.mkDefault true;
        dates = lib.mkDefault "weekly";
      };
    };

    services.openssh = lib.mkIf isNotContainer {
      enable = true;
      openFirewall = lib.mkDefault (!config.custom.gui.enable);
      settings = {
        # use more secure defaults
        PermitRootLogin = lib.mkDefault "prohibit-password";
        PasswordAuthentication = lib.mkDefault false;
      };
    };
  };
}
