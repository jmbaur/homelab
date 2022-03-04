{ config, pkgs, ... }: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.cloudflare = {
      owner = users.users.dhcpcd.name;
      group = users.users.dhcpcd.group;
    };
    secrets.he_tunnelbroker = {
      owner = users.users.dhcpcd.name;
      group = users.users.dhcpcd.group;
    };
  };

  systemd.services.dhcpcd.serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];

  networking.dhcpcd = {
    enable = true;
    persistent = true;
    allowInterfaces = [ "eno1" ];
    extraConfig = ''
      # Disable ipv6 router solicitation
      noipv6rs
      # Override domain settings sent from ISP DHCPD
      static domain_name_servers=
      static domain_search=
      static domain_name=
    '';
    runHook = ''
      case "$reason" in
        "BOUND")
          source /run/secrets/he_tunnelbroker
          source /run/secrets/cloudflare
          ipaddr=$(ip -4 address show dev "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
          ${pkgs.curl}/bin/curl \
            --data "hostname=''${TUNNEL_ID}" \
            --user "''${USERNAME}:''${PASSWORD}" \
            https://ipv4.tunnelbroker.net/nic/update
          ${pkgs.curl}/bin/curl -X POST \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ''${CF_DNS_API_TOKEN}" \
            --data '{"type":"A","name":"jmbaur.com","content":"'"''${ipaddr}"'","proxied":false}' \
            "https://api.cloudflare.com/client/v4/zones/''${ZONE_ID}/dns_records/''${RECORD_ID}"
          ;;
        esac
    '';
  };
}
