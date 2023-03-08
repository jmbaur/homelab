{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.router.enable {
    sops.defaultSopsFile = ./secrets.yaml;
    sops.secrets =
      let
        # wgSecret is a sops secret that has file permissions that can be
        # consumed by systemd-networkd. Reference:
        # https://www.freedesktop.org/software/systemd/man/systemd.netdev.html#PrivateKeyFile=
        wgSecret = { mode = "0640"; group = config.users.groups.systemd-network.name; };
      in
      {
        ipwatch_env = { };
        "wg/mon/artichoke" = wgSecret;
        "wg/iot/artichoke" = wgSecret;
        "wg/www/artichoke" = wgSecret;
        "wg/trusted/artichoke" = wgSecret;
        "wg/iot/phone" = { owner = config.users.users.wg-config-server.name; };
        "wg/trusted/beetroot" = { owner = config.users.users.wg-config-server.name; };
      };

    systemd.network.netdevs.br0.netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };

    systemd.network.netdevs.mon = {
      netdevConfig = {
        Name = "mon";
        Kind = "wireguard";
      };
      wireguardPeers = [ ];
      wireguardConfig.PrivateKeyFile = config.sops.secrets."wg/mon/${config.networking.hostName}".path;
    };

    systemd.network.networks = (lib.genAttrs
      [ "lan1" "lan2" "lan3" "lan4" "lan5" "lan6" "wlP1p1s0" ]
      (name: {
        inherit name;
        bridge = [ config.systemd.network.netdevs.br0.netdevConfig.Name ];
      })) // {
      mon = {
        name = "mon";
        address = [ "fdfb:e2fb:c167:0::1/64" ];
      };
    };

    router.wan = config.systemd.network.links."10-wan".linkConfig.Name;

    router.firewall.interfaces = {
      ${config.systemd.network.networks.lan.name}.allowedTCPPorts = [ 22 ];
      ${config.systemd.network.networks.mon.name}.allowedTCPPorts = [
        9153 # coredns
        9430 # corerad
        config.services.prometheus.exporters.blackbox.port
        config.services.prometheus.exporters.node.port
      ];
      ${config.systemd.network.networks.www.name}.allowedTCPPorts = [
        19531 # systemd-journal-gatewayd
      ];
    };

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
