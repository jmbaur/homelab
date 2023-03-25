{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];

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

  # BTN_0 == 0x100
  systemd.services.reset-button.serviceConfig.ExecStart =
    "${pkgs.dookie}/bin/dookie --device=/dev/input/event0 --key-code=256 --action=restart";
}
