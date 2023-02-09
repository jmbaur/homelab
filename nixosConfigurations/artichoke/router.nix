{ config, lib, pkgs, ... }: {
  # NOTE: This `lib.mkIf` is needed so that this nixos system configuration can
  # be extended in another repo and still pass `nix flake check` in this repo.
  # It is needed since the configuration for options provided by the router
  # module are not defined in this repo.
  config = lib.mkIf config.router.enable {
    router.wan = config.systemd.network.links."10-wan".linkConfig.Name;
    router.firewall.interfaces =
      let
        trusted = {
          allowedTCPPorts = [
            22 # ssh
            69 # tftp
            9153 # coredns
            9430 # corerad
            config.services.iperf3.port
            config.services.prometheus.exporters.blackbox.port
            config.services.prometheus.exporters.kea.port
            config.services.prometheus.exporters.node.port
            config.services.prometheus.exporters.wireguard.port
          ];
          allowedUDPPorts = [ config.services.iperf3.port ];
        };
      in
      {
        ${config.router.inventory.networks.mgmt.physical.interface} = trusted;
        ${config.router.inventory.networks.trusted.physical.interface} = trusted;
        ${config.router.inventory.networks.wg-trusted.physical.interface} = trusted;
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
