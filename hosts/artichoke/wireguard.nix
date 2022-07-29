{ config, lib, pkgs, secrets, inventory, ... }:
let
  mkWgInterface = network:
    let
      wgHost = network.hosts."wg-${network.name}";
      peers = lib.filterAttrs (_: wgHost: wgHost.wgPeer) network.hosts;
      port = 51800 + network.id;
    in
    {
      netdev = {
        netdevConfig = { Name = wgHost.interface; Kind = "wireguard"; };
        wireguardConfig = {
          ListenPort = port;
          PrivateKeyFile = "/run/secrets/${wgHost.name}";
        };
        wireguardPeers = lib.mapAttrsToList
          (_: wgHost: {
            wireguardPeerConfig = {
              PublicKey = wgHost.publicKey;
              AllowedIPs = [
                "${wgHost.ipv4}/32"
                "${wgHost.ipv6.gua}/128"
                "${wgHost.ipv6.ula}/128"
              ];
            };
          })
          peers;
      };
      network = with wgHost; {
        inherit name;
        address = [
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
                  (with wgHost; ([ ipv4 ipv6.gua ipv6.ula ]))
                  ++
                  [ "home.arpa" ];
              };
              Peer = {
                PublicKey =
                  "$(cat /run/secrets/${wgHost.name} | ${pkgs.wireguard-tools}/bin/wg pubkey)";
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

  # TODO(jared): map over all networks that have wireguard set to true
  trusted = mkWgInterface inventory.networks.trusted;
  iot = mkWgInterface inventory.networks.iot;
  work = mkWgInterface inventory.networks.work;
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
