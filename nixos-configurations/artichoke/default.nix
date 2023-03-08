{ config, lib, pkgs, ... }: {
  imports = [ ./router.nix ./hardware-configuration.nix ];

  programs.flashrom.enable = true;
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "update-bios" ''
      ${config.programs.flashrom.package}/bin/flashrom \
        --programmer linux_mtd:dev=0 \
        --write ${pkgs.ubootCN9130_CF_Pro}/spi.img
    '')
  ];

  boot.initrd.systemd.enable = true;

  hardware.clearfog-cn913x.enable = true;

  zramSwap.enable = true;

  custom = {
    server.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    disableZfs = true;
    wgWwwPeer.enable = true;
  };

  networking.hostName = "artichoke";

  system.stateVersion = "23.05";
}
