{ config, pkgs, ... }: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.cloudflare = {
      owner = config.users.users.dhcpcd.name;
      group = config.users.users.dhcpcd.group;
    };
    secrets.he_tunnelbroker = {
      owner = config.users.users.dhcpcd.name;
      group = config.users.users.dhcpcd.group;
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
          ipaddr=$(${pkgs.iproute2}/bin/ip -4 address show dev "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
          echo Updating hurricane electric tunnelbroker with new IP
          ${pkgs.curl}/bin/curl \
            --data "hostname=''${TUNNEL_ID}" \
            --user "''${USERNAME}:''${PASSWORD}" \
            https://ipv4.tunnelbroker.net/nic/update
          echo Updating Cloudflare DNS with new IP
          ${pkgs.curl}/bin/curl \
            --request PUT \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer ''${CF_DNS_API_TOKEN}" \
            --data '{"type":"A","name":"jmbaur.com","content":"'"''${ipaddr}"'","proxied":false}' \
            "https://api.cloudflare.com/client/v4/zones/''${ZONE_ID}/dns_records/''${RECORD_ID}" | ${pkgs.jq}/bin/jq 
          ;;
        esac
    '';
  };
}
