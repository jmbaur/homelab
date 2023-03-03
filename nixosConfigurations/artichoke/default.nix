{ config, pkgs, ... }: {
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
  system.stateVersion = "23.05";

  systemd.network.enable = true;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets =
      let
        # wgSecret is a sops secret that has file permissions that can be
        # consumed by systemd-networkd. Reference:
        # https://www.freedesktop.org/software/systemd/man/systemd.netdev.html#PrivateKeyFile=
        wgSecret = { mode = "0640"; group = config.users.groups.systemd-network.name; };
      in
      {
        ipwatch_env = { };
        "wg/iot/artichoke" = wgSecret;
        "wg/www/artichoke" = wgSecret;
        "wg/trusted/artichoke" = wgSecret;
        "wg/iot/phone" = { owner = config.users.users.wg-config-server.name; };
        "wg/trusted/beetroot" = { owner = config.users.users.wg-config-server.name; };
      };
  };

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
}
