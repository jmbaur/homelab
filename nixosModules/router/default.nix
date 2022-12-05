{ config, pkgs, ... }: {
  imports = [
    ./dhcp.nix
    ./dns.nix
    ./firewall.nix
    ./lan.nix
    ./monitoring.nix
    ./options.nix
    ./wan.nix
    ./wireguard.nix
  ];

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

  services.avahi = {
    enable = false;
    openFirewall = false;
    extraConfig = ''
      [server]
      deny-interfaces=${config.systemd.network.networks.wan.name}
    '';
  };

  services.journald.rateLimitBurst = 5000;

  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  services.iperf3 = {
    enable = true;
    openFirewall = false;
  };

  services.atftpd.enable = true;
  systemd.tmpfiles.rules = [
    "L+ ${config.services.atftpd.root}/netboot.xyz.efi 644 root root - ${pkgs.netbootxyz-efi}"
  ];

  services.ntp = {
    enable = true;
    # continue to serve time to the network in case internet access is lost
    extraConfig = ''
      tos orphan 15
    '';
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
  };
  systemd.network.enable = true;
}
