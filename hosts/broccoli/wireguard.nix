{ config, lib, pkgs, secrets, inventory, ... }:
let
  mkWgInterface = network:
    let
      peers = lib.filterAttrs (_: host: host.wgPeer) network.hosts;
      port = 51800 + network.id;
    in
    {
      netdev = {
        netdevConfig = { Name = network.name; Kind = "wireguard"; };
        wireguardConfig = {
          ListenPort = port;
          PrivateKeyFile = "/run/secrets/${network.name}";
        };
        wireguardPeers = lib.mapAttrsToList
          (_: host: {
            wireguardPeerConfig = {
              PublicKey = host.publicKey;
              AllowedIPs = [
                "${host.ipv4}/32"
                "${host.ipv6.gua}/128"
                "${host.ipv6.ula}/128"
              ];
            };
          })
          peers;
      };
      network = {
        name = network.name;
        address =
          with network.hosts.broccoli; [
            "${ipv4}/${toString network.ipv4Cidr}"
            "${ipv6.gua}/${toString network.ipv6Cidr}"
            "${ipv6.ula}/${toString network.ipv6Cidr}"
          ];
      };
      # TODO(jared): provide full-tunnel and split-tunnel configurations.
      clientConfigs = lib.mapAttrsToList
        (hostname: host:
          let
            scriptName = "wg-config-${hostname}";
            wgConfig = lib.generators.toINI { listsAsDuplicateKeys = true; } {
              Interface = {
                Address = [
                  "${host.ipv4}/${toString network.ipv4Cidr}"
                  "${host.ipv6.gua}/${toString network.ipv6Cidr}"
                  "${host.ipv6.ula}/${toString network.ipv6Cidr}"
                ];
                PrivateKey =
                  "$(cat ${config.age.secrets.${hostname}.path})";
                DNS =
                  (with network.hosts.broccoli; ([ ipv4 ipv6.gua ipv6.ula ]))
                  ++
                  [ "home.arpa" ];
              };
              Peer = {
                PublicKey =
                  "$(cat ${config.age.secrets.${network.name}.path} | ${pkgs.wireguard-tools}/bin/wg pubkey)";
                Endpoint = "vpn.${inventory.tld}:${toString port}";
                AllowedIPs = [ "0.0.0.0/0" "::/0" ];
              };
            };
          in
          pkgs.writeShellScriptBin scriptName ''
            set -eo pipefail
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
          '')
        peers;
    };
  wg-trusted = mkWgInterface inventory.networks.wg-trusted;
  wg-iot = mkWgInterface inventory.networks.wg-iot;
in
{
  systemd.network = {
    netdevs.wg-trusted = wg-trusted.netdev;
    networks.wg-trusted = wg-trusted.network;

    netdevs.wg-iot = wg-iot.netdev;
    networks.wg-iot = wg-iot.network;
  };

  environment.systemPackages =
    wg-trusted.clientConfigs ++ wg-iot.clientConfigs ++ [ pkgs.wireguard-tools ];
}
