{ config, lib, pkgs, ... }:
let
  mkWgInterface = name: { port, ipv4ThirdOctet, subdomain, peers ? [ ] }:
    let
      ipv6FourthHextet = lib.toHexString ipv4ThirdOctet;
    in
    {
      netdev = {
        netdevConfig = {
          Name = name;
          Kind = "wireguard";
        };
        wireguardConfig = {
          ListenPort = port;
          PrivateKeyFile = "/run/secrets/${name}";
        };
        wireguardPeers = map
          (p: {
            wireguardPeerConfig = {
              PublicKey = p.publicKey;
              AllowedIPs = [
                "192.168.${toString ipv4ThirdOctet}.${toString p.ipv4FourthOctet}/32"
                "${config.router.guaPrefix}:${ipv6FourthHextet}::${lib.toHexString p.ipv4FourthOctet}/128"
                "${config.router.ulaPrefix}:${ipv6FourthHextet}::${lib.toHexString p.ipv4FourthOctet}/128"
              ];
            };
          }
          )
          peers;
      };

      network = {
        matchConfig.Name =
          config.systemd.network.netdevs.${name}.netdevConfig.Name;
        networkConfig.Address = [
          "192.168.${toString ipv4ThirdOctet}.1/24"
          "${config.router.ulaPrefix}:${ipv6FourthHextet}::1/64"
          "${config.router.guaPrefix}:${ipv6FourthHextet}::1/64"
        ];
      };

      qrCodes = builtins.listToAttrs (map
        (p: {
          inherit (p) name;
          value = pkgs.writeShellScriptBin "wg-config-${p.name}" ''
            set -eou pipefail

            ${pkgs.qrencode}/bin/qrencode -t ANSIUTF8 << EOF
            [Interface]
            Address=192.168.${toString ipv4ThirdOctet}.${toString p.ipv4FourthOctet}/24,${config.router.guaPrefix}:${ipv6FourthHextet}::${lib.toHexString p.ipv4FourthOctet}/64,${config.router.ulaPrefix}:${ipv6FourthHextet}::${lib.toHexString p.ipv4FourthOctet}/64
            PrivateKey=$(cat ${config.sops.secrets.${p.name}.path})

            [Peer]
            PublicKey=$(cat ${config.sops.secrets.${name}.path} | ${pkgs.wireguard-tools}/bin/wg pubkey)
            Endpoint=${subdomain}.jmbaur.com:${toString port}
            AllowedIPs=0.0.0.0/0,::/0
            EOF
          '';
        })
        peers);
    };

  wg-trusted = mkWgInterface "wg-trusted" {
    port = 51830;
    ipv4ThirdOctet = 130;
    subdomain = "vpn0";
    peers = [ ];
  };

  wg-iot = mkWgInterface "wg-iot" {
    port = 51840;
    ipv4ThirdOctet = 140;
    subdomain = "vpn1";
    peers = [{
      name = "mobile";
      publicKey = "+ejUdGV/k3TQmWOhkM2yAisLcA+eU9A+8YLvLUWSnjY=";
      ipv4FourthOctet = 50;
    }];
  };
in
{
  systemd.network.networks.wg-trusted = wg-trusted.network;
  systemd.network.networks.wg-iot = wg-iot.network;

  systemd.network.netdevs.wg-trusted = wg-trusted.netdev;
  systemd.network.netdevs.wg-iot = wg-iot.netdev;

  environment.systemPackages = [
    pkgs.wireguard-tools
    wg-iot.qrCodes.mobile
  ];
}
