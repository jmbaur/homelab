{ config, lib, pkgs, secrets, inventory, ... }:
let
  mkWgInterface = network:
    let
      wgServerHost = network.hosts.${config.networking.hostName};
      peers = lib.filterAttrs (_: host: host.wgPeer) network.hosts;
      port = 51800 + network.id;
    in
    {
      netdev = {
        netdevConfig = { Name = wgServerHost.interface; Kind = "wireguard"; };
        wireguardConfig = {
          ListenPort = port;
          PrivateKeyFile = config.age.secrets.${network.name}.path;
        };
        wireguardPeers = lib.mapAttrsToList
          (_: peer: {
            wireguardPeerConfig = {
              PublicKey = peer.publicKey;
              AllowedIPs = [
                "${peer.ipv4}/32"
                "${peer.ipv6.ula}/128"
              ];
            };
          })
          peers;
      };
      network = with wgServerHost; {
        inherit (network) name;
        address = [
          "${ipv4}/${toString network.ipv4Cidr}"
          "${ipv6.ula}/${toString network.ipv6Cidr}"
          "${ipv6.gua}/${toString network.ipv6Cidr}"
        ];
      };
      clientConfigs = lib.mapAttrsToList
        (hostname: host:
          let
            scriptName = "wg-config-${hostname}";
            splitTunnelWgConfig = lib.generators.toINI { listsAsDuplicateKeys = true; } {
              Interface = {
                Address = [
                  "${host.ipv4}/${toString network.ipv4Cidr}"
                  "${host.ipv6.ula}/${toString network.ipv6Cidr}"
                  "${host.ipv6.gua}/${toString network.ipv6Cidr}"
                ];
                PrivateKey = "$(cat ${config.age.secrets.${hostname}.path})";
                DNS = (with wgServerHost; ([ ipv4 ipv6.ula ipv6.gua ])) ++ [ "home.arpa" ];
              };
              Peer = {
                PublicKey = "$(cat ${config.age.secrets.${network.name}.path} | ${pkgs.wireguard-tools}/bin/wg pubkey)";
                Endpoint = "vpn.${inventory.tld}:${toString port}";
                AllowedIPs = [
                  network.networkIPv4Cidr
                  network.networkUlaCidr
                  network.networkGuaCidr
                ] ++
                lib.flatten
                  (lib.mapAttrsToList
                    (name: networkInfo: [ networkInfo.networkIPv4Cidr networkInfo.networkUlaCidr networkInfo.networkGuaCidr ])
                    (lib.filterAttrs
                      (name: networkInfo: lib.any (name: network.name == name) networkInfo.includeRoutesTo)
                      inventory.networks
                    )
                  );
              };
            };
            fullTunnelWgConfig = lib.generators.toINI { listsAsDuplicateKeys = true; } {
              Interface = {
                Address = [
                  "${host.ipv4}/${toString network.ipv4Cidr}"
                  "${host.ipv6.ula}/${toString network.ipv6Cidr}"
                  "${host.ipv6.gua}/${toString network.ipv6Cidr}"
                ];
                PrivateKey = "$(cat ${config.age.secrets.${hostname}.path})";
                DNS = (with wgServerHost; ([ ipv4 ipv6.ula ipv6.gua ])) ++ [ "home.arpa" ];
              };
              Peer = {
                PublicKey = "$(cat ${config.age.secrets.${network.name}.path} | ${pkgs.wireguard-tools}/bin/wg pubkey)";
                Endpoint = "vpn.${inventory.tld}:${toString port}";
                AllowedIPs = [ "0.0.0.0/0" "::/0" ];
              };
            };
          in
          pkgs.writeShellScriptBin scriptName ''
            set -eou pipefail
            case "$1" in
            text)
            printf "%s\n" "####################################################################"
            printf "%s\n" "# FULL TUNNEL"
            cat << EOF
            ${fullTunnelWgConfig}
            EOF
            printf "%s\n" "####################################################################"
            printf "%s\n" "# SPLIT TUNNEL"
            cat << EOF
            ${splitTunnelWgConfig}
            EOF
            printf "%s\n" "####################################################################"
            ;;
            qrcode)
            printf "%s\n" "####################################################################"
            printf "%s\n" "# FULL TUNNEL"
            ${pkgs.qrencode}/bin/qrencode -t ANSIUTF8 << EOF
            ${fullTunnelWgConfig}
            EOF
            printf "%s\n" "####################################################################"
            printf "%s\n" "# SPLIT TUNNEL"
            ${pkgs.qrencode}/bin/qrencode -t ANSIUTF8 << EOF
            ${splitTunnelWgConfig}
            EOF
            printf "%s\n" "####################################################################"
            ;;
            *)
            echo Usage: "$0" type-of-config
            echo   where type-of-config can be "text" or "qrcode"
            ;;
            esac
          '')
        peers;
    };

  # TODO(jared): map over all networks that have wireguard set to true
  trusted = mkWgInterface inventory.networks.wg-trusted;
  iot = mkWgInterface inventory.networks.wg-iot;
  work = mkWgInterface inventory.networks.wg-work;
in
{
  systemd.network = {
    netdevs.wg-trusted = trusted.netdev;
    networks.wg-trusted = trusted.network;

    netdevs.wg-iot = iot.netdev;
    networks.wg-iot = iot.network;

    netdevs.wg-work = work.netdev;
    networks.wg-work = work.network;
  };

  environment.systemPackages = [ pkgs.wireguard-tools ] ++
    trusted.clientConfigs ++
    iot.clientConfigs ++
    work.clientConfigs;
}
