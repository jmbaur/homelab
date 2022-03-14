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

      jmbaur.com {
        hosts {
          192.168.10.10 jmbaur.com
          192.168.10.10 www.jmbaur.com
          192.168.10.10 git.jmbaur.com
          192.168.10.10 cache.jmbaur.com
          2001:470:f001:a::a jmbaur.com
          2001:470:f001:a::a www.jmbaur.com
          2001:470:f001:a::a git.jmbaur.com
          2001:470:f001:a::a cache.jmbaur.com
          192.168.20.10 plex.jmbaur.com
          192.168.20.10 radarr.jmbaur.com
          192.168.20.10 sonarr.jmbaur.com
          192.168.20.10 lidarr.jmbaur.com
          fd82:f21d:118d:14::a plex.jmbaur.com
          fd82:f21d:118d:14::a radarr.jmbaur.com
          fd82:f21d:118d:14::a sonarr.jmbaur.com
          fd82:f21d:118d:14::a lidarr.jmbaur.com
        }
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
