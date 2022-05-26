{ pkgs, config, lib, inputs, inventory, ... }:
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

    '' + lib.concatMapStringsSep "\n"
      (network:
        let
          allEntries = lib.mapAttrsToList
            (hostname: host: map
              (ipAddr: "${ipAddr} ${hostname}.${network.domain}")
              (
                host.ipv4
                # TODO(jared): must implement dhcpd6 first
                # ++ host.ipv6
              )
            )
            network.hosts;
          hostsFile = pkgs.writeText
            network.domain
            (lib.concatStringsSep "\n" (lib.flatten allEntries));
        in
        ''
          ${network.domain} {
            hosts ${hostsFile}
          }
        '')
      (with inventory; [
        iot
        mgmt
        publan
        pubwan
        trusted
        work
      ]);
  };
}
