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
          192.168.20.10 jmbaur.com
          192.168.20.10 www.jmbaur.com
          192.168.20.10 git.jmbaur.com
          192.168.20.10 cache.jmbaur.com
          192.168.20.10 plex.jmbaur.com
          fd82:f21d:118d:14::a jmbaur.com
          fd82:f21d:118d:14::a www.jmbaur.com
          fd82:f21d:118d:14::a git.jmbaur.com
          fd82:f21d:118d:14::a cache.jmbaur.com
          fd82:f21d:118d:14::a plex.jmbaur.com
        }
      }

      ${domain} {
        hosts {
          ${lib.concatMapStrings (machine: ''
            ${machine.ipAddress} ${machine.hostName}.${domain}
          '') (with config.services; dhcpd4.machines ++ dhcpd6.machines)}

          ${lib.concatMapStrings (address: ''
            ${address} ${config.networking.hostName}.${domain}
          '') config.systemd.network.networks.mgmt.networkConfig.Address}
        }
      }
    '';
  };
}
