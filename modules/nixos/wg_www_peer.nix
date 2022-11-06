{ config, lib, ... }:
let
  cfg = config.custom.wgWwwPeer;
  wg = import ../../nixosConfigurations/www/wg.nix;
in
{
  options.custom.wgWwwPeer.enable = lib.mkEnableOption "wireguard peer to www";
  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = config.networking.useNetworkd;
      message = "systemd-networkd not used";
    }];
    systemd.network = {
      netdevs.www = {
        netdevConfig = {
          Name = "www";
          Kind = "wireguard";
        };
        wireguardPeers = [{
          wireguardPeerConfig = {
            PublicKey = wg.www.publicKey;
            Endpoint = "www.jmbaur.com:51820";
            PersistentKeepalive = 25;
            AllowedIPs = [ wg.www.ip ];
          };
        }];
        wireguardConfig.PrivateKeyFile = config.sops.secrets."wg/www/${config.networking.hostName}".path;
      };
      networks.www = {
        name = "www";
        address = [ wg.${config.networking.hostName}.ip ];
      };
    };
  };
}
