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
              AllowedIPs =
                (map (ip: "${ip}/32") host.ipv4)
                ++
                (map (ip: "${ip}/128") host.ipv6);
            };
          })
          peers;
      };
      network = {
        matchConfig.Name = network.name;
        networkConfig.Address =
          with network.hosts.broccoli; (
            (map (ip: "${ip}/${toString network.ipv4Cidr}") ipv4)
            ++
            (map (ip: "${ip}/${toString network.ipv6Cidr}") ipv6)
          );
      };
      # TODO(jared): provide full-tunnel and split-tunnel configurations.
      clientConfigs = builtins.listToAttrs (lib.mapAttrsToList
        (hostname: host: {
          name = hostname;
          value =
            let
              scriptName = "wg-config-${hostname}";
              wgConfig = lib.generators.toINI { } {
                Interface = {
                  Address = lib.concatStringsSep "," (
                    (map (ip: "${ip}/${toString network.ipv4Cidr}") host.ipv4)
                    ++
                    (map (ip: "${ip}/${toString network.ipv6Cidr}") host.ipv6)
                  );
                  PrivateKey =
                    "$(cat ${config.sops.secrets.${hostname}.path})";
                  DNS = lib.concatStringsSep "," (with network.hosts.broccoli;
                    ipv4 ++ ipv6 ++ network.domain);
                };
                Peer = {
                  PublicKey =
                    "$(cat ${config.sops.secrets.${network.name}.path} | ${pkgs.wireguard-tools}/bin/wg pubkey)";
                  Endpoint = "vpn.jmbaur.com:${toString port}";
                  AllowedIPs = lib.concatStringsSep "," [ "0.0.0.0/0" "::/0" ];
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
            '';
        })
        peers);
    };
  wgTrusted = mkWgInterface inventory.wgTrusted;
  wgIot = mkWgInterface inventory.wgIot;
in
{
  systemd.network = {
    netdevs.wgTrusted = wgTrusted.netdev;
    networks.wgTrusted = wgTrusted.network;

    netdevs.wgIot = wgIot.netdev;
    networks.wgIot = wgIot.network;
  };

  environment.systemPackages = [
    pkgs.wireguard-tools
    wgTrusted.clientConfigs.beetroot
    wgIot.clientConfigs.pixel
  ];
}
