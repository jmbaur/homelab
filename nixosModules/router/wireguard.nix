{ config, lib, pkgs, ... }:
let
  mkWgInterface = network:
    let
      routerPublicKey = network.wireguard.publicKey;
      routerIPv4 = "${network._networkIPv4SignificantBits}.1";
      routerIPv6Gua = "${network._networkGuaPrefix}::1";
      routerIPv6Ula = "${network._networkUlaPrefix}::1";
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
          network.hosts;
      };
      network = {
        inherit (network) name;
        address = [
          "${routerIPv4}/${toString network._ipv4Cidr}"
          "${routerIPv6Gua}/${toString network._ipv6GuaCidr}"
          "${routerIPv6Ula}/${toString network._ipv6UlaCidr}"
        ];
      };
      clientConfigs = lib.mapAttrsToList
        (hostname: host:
          let
            scriptName = "wg-config-${hostname}";
            splitTunnelWgConfig = lib.generators.toINI { listsAsDuplicateKeys = true; } {
              Interface = {
                Address = [
                  "${host.ipv4}/${toString network._ipv4Cidr}"
                  "${host.ipv6.gua}/${toString network._ipv6GuaCidr}"
                  "${host.ipv6.ula}/${toString network._ipv6UlaCidr}"
                ];
                PrivateKey = "$(cat ${config.sops.secrets."wg/${lib.replaceStrings ["wg-"] [""] network.name}/${hostname}".path})";
                DNS = (([ routerIPv4 routerIPv6Ula ])) ++ [ "home.arpa" ];
              };
              Peer = {
                PublicKey = routerPublicKey;
                Endpoint = "vpn.jmbaur.com:${toString port}";
                AllowedIPs = [
                  network._networkIPv4Cidr
                  network._networkGuaCidr
                  network._networkUlaCidr
                ] ++
                lib.flatten (
                  map
                    (name: with config.custom.inventory.networks.${name}; [ _networkIPv4Cidr _networkGuaCidr _networkUlaCidr ])
                    network.includeRoutesTo
                );
              };
            };
            fullTunnelWgConfig = lib.generators.toINI { listsAsDuplicateKeys = true; } {
              Interface = {
                Address = [
                  "${host.ipv4}/${toString network._ipv4Cidr}"
                  "${host.ipv6.gua}/${toString network._ipv6GuaCidr}"
                  "${host.ipv6.ula}/${toString network._ipv6UlaCidr}"
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
        network.hosts;
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
  environment.systemPackages = [ pkgs.wireguard-tools ] ++ (lib.flatten (lib.mapAttrsToList (_: x: x.clientConfigs) wireguardNetworks));
}
