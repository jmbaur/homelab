{ config, lib, pkgs, ... }:
let
  cfg = config.custom.wg-mesh;

  inventory = import ./inventory.nix;
  host = inventory."${cfg.name}";
in
{

  options.custom.wg-mesh = with lib; {
    enable = mkEnableOption "wireguard mesh network node";
    name = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = mdDoc "The name of the host";
    };
    peers = mkOption {
      type = types.attrsOf (types.submodule ({ name, config, ... }: {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
            description = mdDoc "The name of the peer";
          };
          extraOptions = mkOption {
            type = types.attrs;
            default = { };
            description = mdDoc ''
              Options that would go under the [WireguardPeer] section in
              systemd.netdev(5).
            '';
          };
        };
      }));
      default = { };
      example = ''
        {
          peer1.extraOptions.PersistentKeepalive = 25;
        }
      '';
      description = mdDoc ''
        Peers of this wg node
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.wireguard-tools ];
    systemd.network.netdevs.wg0 = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
      };
      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets.wg0.path;
        ListenPort = 51820;
      };
      wireguardPeers = map
        ({ name, extraOptions, ... }:
          let
            peer = inventory.${name};
          in
          {
            wireguardPeerConfig = lib.recursiveUpdate extraOptions {
              AllowedIPs = [ (peer.ip + "/128") ];
              PublicKey = peer.publicKey;
            };
          })
        (lib.attrValues cfg.peers);
    };

    systemd.network.networks.wg0 = {
      name = config.systemd.network.netdevs.wg0.netdevConfig.Name;
      address = [ (host.ip + "/64") ];
    };
  };
}
