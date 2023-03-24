{ config, pkgs, ... }: {
  imports = [ ./router.nix ./hardware-configuration.nix ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];
  networking.wireless.athUserRegulatoryDomain = true;

  programs.flashrom.enable = true;
  environment.systemPackages = with pkgs; [
    tshark
    tcpdump
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
  };

  networking.hostName = "artichoke";
  networking.firewall.logRefusedConnections = false;

  system.stateVersion = "23.05";
}
