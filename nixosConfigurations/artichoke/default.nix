{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  hardware.clearfog-cn913x.enable = true;

  programs.flashrom.enable = true;

  zramSwap.enable = true;
  system.stateVersion = "23.05";

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
        "wg/iot/phone" = { };
        "wg/www/artichoke" = wgSecret;
        "wg/trusted/artichoke" = wgSecret;
        "wg/trusted/beetroot" = { };
      };
  };

  custom = {
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    disableZfs = true;
    wgWwwPeer.enable = true;
  };

  networking.hostName = "artichoke";
  networking.nftables.firewall.interfaces =
    let
      trusted = {
        allowedTCPPorts = [
          22 # ssh
          69 # tftp
          9153 # coredns
          config.services.iperf3.port
          config.services.prometheus.exporters.blackbox.port
          config.services.prometheus.exporters.kea.port
          config.services.prometheus.exporters.node.port
          config.services.prometheus.exporters.wireguard.port
        ];
        allowedUDPPorts = [ config.services.iperf3.port ];
      };
    in
    {
      ${config.custom.inventory.networks.mgmt.physical.interface} = trusted;
      ${config.custom.inventory.networks.trusted.physical.interface} = trusted;
      ${config.custom.inventory.networks.wg-trusted.physical.interface} = trusted;
      ${config.systemd.network.networks.www.name}.allowedTCPPorts = [
        19531 # systemd-journal-gatewayd
      ];
    };
}
