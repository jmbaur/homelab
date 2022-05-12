{ inputs, config, lib, ... }:
let
  dnsServers = map
    (ip: "tls://" + ip)
    [ "9.9.9.9" "2620:fe::fe" "149.112.112.112" "2620:fe::9" ];
in
{
  services.coredns = {
    enable = true;
    config = ''
      . {
        hosts ${inputs.hosts}/hosts {
          fallthrough
        }
        forward . ${toString dnsServers} {
          tls_servername dns.quad9.net
          health_check 5s
        }
        prometheus :9153
      }
    '';
  };
}
