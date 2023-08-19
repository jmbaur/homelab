{ config, lib, pkgs, ... }: {
  imports = [ ./router.nix ./hardware-configuration.nix ];

  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];

  networking.hostName = "squash";

  hardware.armada-a38x.enable = true;

  custom = {
    crossCompile.enable = true;
    server.enable = true;
    disableZfs = true;
    deployee = {
      enable = true;
      sshTarget = "root@squash.home.arpa";
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
  };

  zramSwap.enable = true;
  system.stateVersion = "23.05";

  system.build.firmware = pkgs.ubootClearfogSpi;

  programs.flashrom.enable = lib.mkDefault true;
  environment.systemPackages = lib.optional config.programs.flashrom.enable
    (pkgs.writeShellScriptBin "update-firmware" ''
      ${config.programs.flashrom.package}/bin/flashrom \
      --programmer linux_mtd:dev=0 \
      --write ${config.system.build.firmware}
    '');

  systemd.services.reset-button = {
    # BTN_0 == 0x100
    serviceConfig.ExecStart = "${pkgs.dookie}/bin/dookie --device=/dev/input/event0 --key-code=0x100 --action=restart";
    wantedBy = [ "multi-user.target" ];
  };
}
