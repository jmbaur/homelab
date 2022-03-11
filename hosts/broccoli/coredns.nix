{ config, lib, ... }:
let
  quad9-ipv4-1 = "9.9.9.9";
  quad9-ipv4-2 = "149.112.112.112";
  quad9-ipv6-1 = "2620:fe::fe";
  quad9-ipv6-2 = "2620:fe::9";
  domain = lib.last config.networking.search;
in
{
  services.coredns = {
    enable = true;
    config = ''
      . {
        hosts {
          fallthrough
        }
        forward . tls://${quad9-ipv4-1} tls://${quad9-ipv4-2} tls://${quad9-ipv6-1} tls://${quad9-ipv6-2} {
          tls_servername dns.quad9.net
          health_check 5s
        }
        prometheus :9153
      }

      ${domain} {
        hosts {
          ${lib.concatMapStrings (machine: ''
            ${machine.ipAddress} ${machine.hostName}.${domain}
          '') config.services.dhcpd4.machines}

          ${(lib.last config.networking.interfaces.mgmt.ipv4.addresses).address} ${config.networking.hostName}.${domain}
        }
      }
    '';
  };
}
