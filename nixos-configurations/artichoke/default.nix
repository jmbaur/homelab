{ config, lib, pkgs, ... }: {
  imports = [ ./router.nix ./hardware-configuration.nix ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];
  networking.wireless.athUserRegulatoryDomain = true;

  programs.flashrom.enable = lib.mkDefault true;
  environment.systemPackages = lib.optional config.programs.flashrom.enable
    (pkgs.writeShellScriptBin "update-firmware" ''
      ${config.programs.flashrom.package}/bin/flashrom \
      --programmer linux_mtd:dev=0 \
      --write ${pkgs.ubootCN9130_CF_Pro}/spi.img
    '');

  boot.initrd.systemd.enable = true;

  hardware.clearfog-cn913x.enable = true;

  zramSwap.enable = true;

  custom = {
    crossCompile.enable = true;
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

  # BTN_0 == 0x100
  systemd.services.reset-button = {
    serviceConfig.ExecStart =
      "${pkgs.dookie}/bin/dookie --device=/dev/input/event0 --key-code=0x100 --action=restart";
    wantedBy = [ "multi-user.target" ];
  };
}
