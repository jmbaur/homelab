{ config, inventory, ... }:
let
  network = inventory.networks.wg-public;
in
{
  systemd.network = {
    netdevs.wg-public = {
      netdevConfig = {
        Name = "wg-public";
        Kind = "wireguard";
      };
      wireguardConfig.PrivateKeyFile = config.age.secrets.wg-public-artichoke.path;
      wireguardPeers = [{
        wireguardPeerConfig = {
          PublicKey = network.hosts.www.publicKey;
          Endpoint = "www.jmbaur.com:${toString (51800 + network.id)}";
          PersistentKeepalive = 25;
          AllowedIPs = with network.hosts.www; [
            "${ipv4}/32"
            "${ipv6.ula}/128"
            "${ipv6.gua}/128"
          ];
        };
      }];
    };
    networks.wg-public = {
      name = "wg-public";
      address = with network.hosts.artichoke; [
        "${ipv4}/${toString network.ipv4Cidr}"
        "${ipv6.gua}/${toString network.ipv6Cidr}"
        "${ipv6.ula}/${toString network.ipv6Cidr}"
      ];
    };
  };
}
