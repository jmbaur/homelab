{ config, lib, inventory, ... }:
let
  cfg = config.custom.wgWwwPeer;
in
{
  options.custom.wgWwwPeer.enable = lib.mkEnableOption "wireguard peer to www";
  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = config.networking.useNetworkd;
      message = "systemd-networkd not used";
    }];
    systemd.network = let wgPublic = inventory.networks.wg-public; in
      {
        netdevs.wg-public = {
          netdevConfig = {
            Name = "wg-public";
            Kind = "wireguard";
          };
          wireguardPeers = [{
            wireguardPeerConfig = {
              PublicKey = wgPublic.hosts.www.publicKey;
              Endpoint = "www.jmbaur.com:${toString (51800 + wgPublic.id)}";
              PersistentKeepalive = 25;
              AllowedIPs = with wgPublic.hosts.www; [
                "${ipv4}/32"
                "${ipv6.ula}/128"
              ];
            };
          }];
          wireguardConfig.PrivateKeyFile = config.sops.secrets."wg/public/${config.networking.hostName}".path;
        };
        networks.wg-public = {
          name = "wg-public";
          address = with wgPublic.hosts.${config.networking.hostName}; [
            "${ipv4}/${toString wgPublic.ipv4Cidr}"
            "${ipv6.ula}/${toString wgPublic.ipv6Cidr}"
          ];
        };
      };
  };
}

