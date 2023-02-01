{ config, lib, pkgs, ... }:
let
  mkWgInterface = network:
    let
      routerPrivateKeyPath = network.wireguard.privateKeyPath;
      routerPublicKey = network.wireguard.publicKey;
      port = 51800 + network.id;
    in
    {
      netdev = {
        netdevConfig = { Name = network.name; Kind = "wireguard"; };
        wireguardConfig = {
          ListenPort = port;
          PrivateKeyFile = routerPrivateKeyPath;
        };
        wireguardPeers = lib.mapAttrsToList
          (_: peer: {
            wireguardPeerConfig = {
              PublicKey = peer.publicKey;
              AllowedIPs = [
                "${peer._computed._ipv4}/32"
                "${peer._computed._ipv6.gua}/128"
                "${peer._computed._ipv6.ula}/128"
              ];
            };
          })
          (lib.filterAttrs (name: _: name != "_router") network.hosts);
      };
      network = {
        inherit (network) name;
        address = [
          "${network.hosts._router._computed._ipv4Cidr}"
          "${network.hosts._router._computed._ipv6.guaCidr}"
          "${network.hosts._router._computed._ipv6.ulaCidr}"
        ];
      };
      clientConfigs = lib.mapAttrsToList
        (_: host:
          let
            scriptName = "wg-config-${host.name}";
            splitTunnelWgConfig = lib.generators.toINI { listsAsDuplicateKeys = true; } {
              Interface = {
                Address = [
                  "${host._computed._ipv4Cidr}"
                  "${host._computed._ipv6.guaCidr}"
                  "${host._computed._ipv6.ulaCidr}"
                ];
                PrivateKey = "$(cat ${host.privateKeyPath})";
                DNS = (([ network.hosts._router._computed._ipv4 network.hosts._router._computed._ipv6.ula ])) ++ [ network.domain "home.arpa" ];
              };
              Peer = {
                PublicKey = routerPublicKey;
                Endpoint = "vpn.jmbaur.com:${toString port}";
                AllowedIPs = [
                  network._computed._networkIPv4Cidr
                  network._computed._networkGuaCidr
                  network._computed._networkUlaCidr
                ] ++
                lib.flatten (
                  map
                    (name: with config.router.inventory.networks.${name}; [ _computed._networkIPv4Cidr _computed._networkGuaCidr _computed._networkUlaCidr ])
                    network.includeRoutesTo
                );
              };
            };
            fullTunnelWgConfig = lib.generators.toINI { listsAsDuplicateKeys = true; } {
              Interface = {
                Address = [
                  "${host._computed._ipv4Cidr}"
                  "${host._computed._ipv6.guaCidr}"
                  "${host._computed._ipv6.ulaCidr}"
                ];
                PrivateKey = "$(cat ${host.privateKeyPath})";
                DNS = (([ network.hosts._router._computed._ipv4 network.hosts._router._computed._ipv6.ula ])) ++ [ network.domain "home.arpa" ];
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
        (lib.filterAttrs (name: _: name != "_router") network.hosts);
    };

  wireguardNetworks = lib.mapAttrs
    (_: mkWgInterface)
    (lib.filterAttrs
      (_: network: network.wireguard.enable)
      config.router.inventory.networks);
in
{
  systemd.network.netdevs = lib.mapAttrs (_: x: x.netdev) wireguardNetworks;
  systemd.network.networks = lib.mapAttrs (_: x: x.network) wireguardNetworks;
  environment.systemPackages = [ pkgs.wireguard-tools ] ++ (lib.flatten (lib.mapAttrsToList (_: x: x.clientConfigs) wireguardNetworks));
}
