{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.custom.common;
  isNotContainer = !config.boot.isContainer;
in
with lib; {
  options.custom.common.enable = mkEnableOption "common config" // { default = true; };

  config = mkIf cfg.enable {
    # NOTE: this should be set explicitly if it is actually needed
    system.stateVersion = lib.mkDefault "23.11";

    environment.systemPackages = [ pkgs.nixos-kexec pkgs.bottom pkgs.tmux ];
    environment.defaultPackages = [ ];

    programs.vim.defaultEditor = true;

    security.sudo.extraRules = [{ groups = [ "wheel" ]; commands = [{ command = "/run/current-system/sw/bin/networkctl"; options = [ "NOPASSWD" ]; }]; }];

    networking.nftables.enable = mkDefault true;

    boot.tmp.cleanOnBoot = mkDefault isNotContainer;
    boot.loader.grub.configurationLimit = mkDefault 50;
    boot.loader.systemd-boot.configurationLimit = mkDefault 50;

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
      gc = mkIf isNotContainer {
        automatic = mkDefault true;
        dates = mkDefault "weekly";
      };
    };

    services.openssh = mkIf isNotContainer {
      enable = true;
      openFirewall = lib.mkDefault (!config.custom.gui.enable);
      settings = {
        # use more secure defaults
        PermitRootLogin = mkDefault "prohibit-password";
        PasswordAuthentication = mkDefault false;
      };
    };
  };
}
