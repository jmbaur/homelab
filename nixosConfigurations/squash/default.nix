{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  boot.initrd.systemd.enable = true;
  networking.hostName = "squash";
  networking.useNetworkd = true;
  hardware.armada-a38x.enable = true;
  custom = {
    server.enable = true;
    disableZfs = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
  };
  zramSwap.enable = true;
  system.stateVersion = "23.05";

  programs.flashrom.enable = true;
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "update-bios" ''
      ${config.programs.flashrom.package}/bin/flashrom \
        --programmer linux_mtd:dev=0 \
        --write ${pkgs.ubootClearfogSpi}/spi.img
    '')
  ];
}
