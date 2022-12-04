{ config, lib, pkgs, ... }:
let
  mkWgInterface = network:
    let
      routerPublicKey = network.wireguard.publicKey;
      routerIPv4 = "${network.networkIPv4SignificantBits}.1";
      routerIPv6Gua = "${network.networkGuaPrefix}::1";
      routerIPv6Ula = "${network.networkUlaPrefix}::1";
      peers = lib.filterAttrs (_: host: host.wgPeer) network.hosts;
      port = 51800 + network.id;
    in
    {
      netdev = {
        netdevConfig = { Name = network.name; Kind = "wireguard"; };
        wireguardConfig = {
          ListenPort = port;
          PrivateKeyFile = config.sops.secrets."wg/${lib.replaceStrings ["wg-"] [""] network.name}/${config.networking.hostName}".path;
        };
        wireguardPeers = lib.mapAttrsToList
          (_: peer: {
            wireguardPeerConfig = {
              PublicKey = peer.publicKey;
              AllowedIPs = [
                "${peer.ipv4}/32"
                "${peer.ipv6.gua}/128"
                "${peer.ipv6.ula}/128"
              ];
            };
          })
          peers;
      };
      network = {
        inherit (network) name;
        address = [
          "${routerIPv4}/${toString network.ipv4Cidr}"
          "${routerIPv6Gua}/${toString network.ipv6Cidr}"
          "${routerIPv6Ula}/${toString network.ipv6Cidr}"
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
                  "${host.ipv6.gua}/${toString network.ipv6Cidr}"
                  "${host.ipv6.ula}/${toString network.ipv6Cidr}"
                ];
                PrivateKey = "$(cat ${config.sops.secrets."wg/${lib.replaceStrings ["wg-"] [""] network.name}/${hostname}".path})";
                DNS = (([ routerIPv4 routerIPv6Ula ])) ++ [ "home.arpa" ];
              };
              Peer = {
                PublicKey = routerPublicKey;
                Endpoint = "vpn.jmbaur.com:${toString port}";
                AllowedIPs = [
                  network.networkIPv4Cidr
                  network.networkGuaCidr
                  network.networkUlaCidr
                ] ++
                lib.flatten (
                  map
                    (name: with config.custom.inventory.networks.${name}; [ networkIPv4Cidr networkGuaCidr networkUlaCidr ])
                    network.includeRoutesTo
                );
              };
            };
            fullTunnelWgConfig = lib.generators.toINI { listsAsDuplicateKeys = true; } {
              Interface = {
                Address = [
                  "${host.ipv4}/${toString network.ipv4Cidr}"
                  "${host.ipv6.gua}/${toString network.ipv6Cidr}"
                  "${host.ipv6.ula}/${toString network.ipv6Cidr}"
                ];
                PrivateKey = "$(cat ${config.sops.secrets."wg/${lib.replaceStrings ["wg-"] [""] network.name}/${hostname}".path})";
                DNS = (([ routerIPv4 routerIPv6Ula ])) ++ [ "home.arpa" ];
              };
              Peer = {
                PublicKey = routerPublicKey;
                Endpoint = "vpn.jmbaur.com:${toString port}";
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

  wireguardNetworks = lib.mapAttrs
    (_: mkWgInterface)
    (lib.filterAttrs
      (_: network: network.wireguard.enable)
      config.custom.inventory.networks);
in
{
  systemd.network.netdevs = lib.mapAttrs (_: x: x.netdev) wireguardNetworks;
  systemd.network.networks = lib.mapAttrs (_: x: x.network) wireguardNetworks;
  environment.systemPackages = [ pkgs.wireguard-tools ] ++ (lib.mapAttrsToList (_: x: x.clientConfigs) wireguardNetworks);
}
