{ config, lib, pkgs, ... }:
let
  mkWgInterface = name: { port, ipv4ThirdOctet, peers ? [ ] }:
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

      # TODO(jared): provide full-tunnel and split-tunnel configurations.
      clientConfigs = builtins.listToAttrs (map
        (p: {
          inherit (p) name;
          value =
            let
              scriptName = "wg-config-${p.name}";
              wgConfig = ''
                [Interface]
                Address=192.168.${toString ipv4ThirdOctet}.${toString p.ipv4FourthOctet}/24,${config.router.guaPrefix}:${ipv6FourthHextet}::${lib.toHexString p.ipv4FourthOctet}/64,${config.router.ulaPrefix}:${ipv6FourthHextet}::${lib.toHexString p.ipv4FourthOctet}/64
                PrivateKey=$(cat ${config.sops.secrets.${p.name}.path})
                DNS=192.168.${toString ipv4ThirdOctet}.1,${config.router.guaPrefix}:${ipv6FourthHextet}::1,${config.router.ulaPrefix}:${ipv6FourthHextet}::1

                [Peer]
                PublicKey=$(cat ${config.sops.secrets.${name}.path} | ${pkgs.wireguard-tools}/bin/wg pubkey)
                Endpoint=vpn.jmbaur.com:${toString port}
                AllowedIPs=0.0.0.0/0,::/0
              '';
            in
            pkgs.writeShellScriptBin scriptName ''
              case "$1" in
                text)
                  cat << EOF
              ${wgConfig}
              EOF
                  ;;
                qrcode)
                  ${pkgs.qrencode}/bin/qrencode -t ANSIUTF8 << EOF
              ${wgConfig}
              EOF
                  ;;
                *)
                  cat <<EOF
              Usage: ${scriptName} type-of-config
                where type-of-config can be "text" or "qrcode"
              EOF
                  ;;
              esac
            '';
        })
        peers);
    };

  wg-trusted = mkWgInterface "wg-trusted" {
    port = 51830;
    ipv4ThirdOctet = 130;
    peers = [{
      name = "beetroot";
      publicKey = "T+zc4lpoEgxPIKEBr9qXiAzb/ruRbqZuVrih+0rGs2M=";
      ipv4FourthOctet = 50;
    }];
  };

  wg-iot = mkWgInterface "wg-iot" {
    port = 51840;
    ipv4ThirdOctet = 140;
    peers = [{
      name = "pixel";
      publicKey = "pCvnlCWnM46XY3+327rQyOPA91wajC1HPTmP/5YHcy8=";
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
    wg-trusted.clientConfigs.beetroot
    wg-iot.clientConfigs.pixel
  ];
}
