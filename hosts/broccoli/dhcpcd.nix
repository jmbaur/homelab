{ config, pkgs, ... }: {
  sops = {
    # defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    # secrets.he_tunnelbroker = {
    # owner = users.users.dhcpcd.name;
    # group = users.users.dhcpcd.group;
    # };
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
          if [ ! -f /run/secrets/he_tunnelbroker ]; then
            echo "no tunnelbroker secrets"
            exit 1
          fi
          . /run/secrets/he_tunnelbroker
          ${pkgs.curl}/bin/curl \
          --data "hostname=''${TUNNEL_ID}" \
          --user "''${USERNAME}:''${PASSWORD}" \
          https://ipv4.tunnelbroker.net/nic/update
          ;;
        esac
    '';
  };
}
