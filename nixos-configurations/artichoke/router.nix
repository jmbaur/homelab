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
      firewall = {
        trustedIPs = [ wg.beetroot.ip ];
        ips."${wg.okra.ip}".allowedTCPPorts = [
          19531 # systemd-journal-gatewayd
          9153 # coredns
          9430 # corerad
          config.services.prometheus.exporters.blackbox.port
          config.services.prometheus.exporters.node.port
        ];
      };
    };

    systemd.network.networks = (lib.genAttrs
      [ "lan1" "lan2" "lan3" "lan4" "lan5" "lan6" "wlp1s0" ]
      (name: {
        inherit name;
        bridge = [ config.systemd.network.netdevs.br0.netdevConfig.Name ];
        linkConfig.ActivationPolicy = "always-up";
      }));

    router.lanInterface = config.systemd.network.netdevs.br0.netdevConfig.Name;
    router.wanInterface = config.systemd.network.links."10-wan".linkConfig.Name;

    networking.firewall.interfaces.${config.systemd.network.networks.lan.name}.allowedTCPPorts = [ 22 ];

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

    # monitoring
    services.journald.enableHttpGateway = true;
    services.prometheus.exporters = {
      blackbox = {
        enable = false;
        configFile = toString ((pkgs.formats.yaml { }).generate "blackbox-config" {
          modules = {
            icmpv6_connectivity = {
              prober = "icmp";
              timeout = "5s";
              icmp = {
                preferred_ip_protocol = "ip6";
                ip_protocol_fallback = false;
              };
            };
            icmpv4_connectivity = {
              prober = "icmp";
              timeout = "5s";
              icmp = {
                preferred_ip_protocol = "ip4";
                ip_protocol_fallback = false;
              };
            };
          };
        });
      };
      node = {
        enable = true;
        enabledCollectors = [ "ethtool" "network_route" "systemd" ];
      };
    };

  };
}
