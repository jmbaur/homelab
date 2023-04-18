{ config, lib, ... }:
let
  wg = import ../../nixos-modules/mesh-network/inventory.nix;
in
{
  config = lib.mkIf config.router.enable {
    sops.defaultSopsFile = ./secrets.yaml;
    sops.secrets.wg0 = { mode = "0640"; group = config.users.groups.systemd-network.name; };

    systemd.network.netdevs.br0.netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };

    custom.wg-mesh = {
      enable = true;
      peers.beetroot = { };
      peers.okra = { };
      peers.rhubarb = { };
      firewall = {
        trustedIPs = [ wg.beetroot.ip ];
        ips."${wg.okra.ip}".allowedTCPPorts = [
          19531 # systemd-journal-gatewayd
          9153 # coredns
          9430 # corerad
          config.services.prometheus.exporters.blackbox.port
          config.services.prometheus.exporters.node.port
        ];
      };
    };


    systemd.network.networks = (lib.genAttrs
      [
        "lan1"
        "lan2"
        "lan3"
        "lan4"
        "lan5"
        "wlp1s0"
        # link shows up as wlan0/wlan1 inconsistently
        "wlan0"
        "wlan1"
      ]
      (name: {
        inherit name;
        bridge = [ config.systemd.network.netdevs.br0.netdevConfig.Name ];
        linkConfig = {
          ActivationPolicy = "always-up";
          RequiredForOnline = "no";
        };
      }));

    router.lanInterface = config.systemd.network.netdevs.br0.netdevConfig.Name;
    router.wanInterface = config.systemd.network.links."10-wan".linkConfig.Name;

    networking.firewall.interfaces.${config.systemd.network.networks.lan.name}.allowedTCPPorts = [ 22 ];
  };
}
