{ config, lib, pkgs, ... }:
let
  wg = import ../../nixos-modules/mesh-network/inventory.nix;
in
{
  config = lib.mkIf config.router.enable {
    sops.defaultSopsFile = ./secrets.yaml;
    sops.secrets = {
      ipwatch_env = { };
      wg0 = { mode = "0640"; group = config.users.groups.systemd-network.name; };
    };

    systemd.network.netdevs.br0.netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };

    custom.wg-mesh = {
      enable = true;
      peers.beetroot = { };
      peers.okra = { };
      peers.rhubarb = { };
    };

    systemd.network.networks = (lib.genAttrs
      [ "lan1" "lan2" "lan3" "lan4" "lan5" "lan6" "wlP1p1s0" ]
      (name: {
        inherit name;
        bridge = [ config.systemd.network.netdevs.br0.netdevConfig.Name ];
      }));

    router.lanInterface = config.systemd.network.netdevs.br0.netdevConfig.Name;
    router.wanInterface = config.systemd.network.links."10-wan".linkConfig.Name;

    router.firewall.allowedUDPPorts = [ config.systemd.network.netdevs.wg0.wireguardConfig.ListenPort ];

    router.firewall.extraInputRules =
      let
        monPorts = lib.concatMapStringsSep ", " toString [
          19531 # systemd-journal-gatewayd
          9153 # coredns
          9430 # corerad
          config.services.prometheus.exporters.blackbox.port
          config.services.prometheus.exporters.node.port
        ];
      in
      ''
        ip6 saddr ${wg.okra.ip} meta l4proto tcp th dport { ${monPorts} } accept
      '' +
      # Allow all traffic from beetroot
      ''
        ip6 saddr ${wg.beetroot.ip} accept
      '';

    router.firewall.interfaces.${config.systemd.network.networks.lan.name}.allowedTCPPorts = [ 22 ];

    services.ipwatch = {
      enable = true;
      extraArgs = [ "-4" ];
      filters = [ "!IsLoopback" "!IsPrivate" "IsGlobalUnicast" "IsValid" ];
      hookEnvironmentFile = config.sops.secrets.ipwatch_env.path;
      interfaces = [ config.systemd.network.networks.wan.name ];
      hooks =
        let
          updateCloudflare = pkgs.writeShellScript "update-cloudflare" ''
            ${pkgs.curl}/bin/curl \
              --silent \
              --show-error \
              --request PUT \
              --header "Content-Type: application/json" \
              --header "Authorization: Bearer ''${CF_DNS_API_TOKEN}" \
              --data '{"type":"A","name":"vpn.jmbaur.com","content":"'"''${ADDR}"'","proxied":false}' \
              "https://api.cloudflare.com/client/v4/zones/''${CF_ZONE_ID}/dns_records/''${VPN_CF_RECORD_ID}" | ${pkgs.jq}/bin/jq
          '';
          updateHE = pkgs.writeShellScript "update-he" ''
            ${pkgs.curl}/bin/curl \
              --silent \
              --show-error \
              --data "hostname=''${HE_TUNNEL_ID}" \
              --user "''${HE_USERNAME}:''${HE_PASSWORD}" \
              https://ipv4.tunnelbroker.net/nic/update
          '';
        in
        [ "internal:echo" "executable:${updateCloudflare}" "executable:${updateHE}" ];
    };
  };
}