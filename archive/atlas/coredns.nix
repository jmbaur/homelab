{ config, lib, pkgs, ... }:
let hosts = import ../hosts.nix;
in
{
  services.coredns = {
    enable = true;
    config = ''
      # Root zone
      . {
        forward . tls://1.1.1.1 tls://1.0.0.1 tls://2606:4700:4700::1111 tls://2606:4700:4700::1001 {
          tls_servername tls.cloudflare-dns.com
          health_check 5s
        }
        prometheus :9153
      }

      # Internal zone
      ${hosts.domain} {
        hosts {
          ${
            lib.strings.concatMapStrings (host: ''
              ${host.ipAddress} ${host.hostName}.${hosts.domain}
            '') (lib.attrsets.attrValues hosts.hosts ++ [ hosts.router ])
          }
        }
        prometheus :9153
      }
    '';
  };

}
