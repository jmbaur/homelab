{ pkgs, config, lib, inventory, ... }:
let
  # coredns-utils = pkgs.callPackage ./coredns-utils.nix { };
  mkDotDns = map (ip: "tls://${ip}");
  googleDns = {
    servers = mkDotDns [ "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844" ];
    serverName = "dns.google";
  };
  cloudflareDns = {
    servers = mkDotDns [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
    serverName = "cloudflare-dns.com";
  };
  quad9Dns = {
    servers = mkDotDns [ "9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::9" ];
    serverName = "dns.quad9.net";
  };
  quad9DnsWithECS = {
    servers = mkDotDns [ "9.9.9.11" "149.112.112.11" "2620:fe::11" "2620:fe::fe:11" ];
    serverName = "dns11.quad9.net";
  };
in
{
  networking.nameservers = [ "127.0.0.1" "::1" ];
  services.resolved = {
    enable = true;
    extraConfig = ''
      DNSStubListener=no
    '';
  };

  services.coredns = {
    enable = true;
    config = ''
      . {
        hosts ${pkgs.stevenblack-blocklist}/hosts {
          fallthrough
        }
        # unused: ${googleDns.serverName} ${toString googleDns.servers}
        # unused: ${cloudflareDns.serverName} ${toString cloudflareDns.servers}
        # unused: ${quad9DnsWithECS.serverName} ${toString quad9DnsWithECS.servers}
        forward . ${toString quad9Dns.servers} {
          tls_servername ${quad9Dns.serverName}
          policy random
          health_check 5s
        }
        cache 30
        errors {
          consolidate 5m ".* i/o timeout$" warning
          consolidate 30s "^Failed to .+"
        }
        prometheus :9153
      }

    '' + lib.concatMapStringsSep "\n"
      (network:
        let
          allEntries = lib.flatten (lib.mapAttrsToList
            (hostname: host: [
              "${host.ipv4} ${hostname}.${network.domain}"
              "${host.ipv6.ula} ${hostname}.${network.domain}"
            ])
            network.hosts);
          hostsFile = pkgs.writeText "${network.domain}.hosts" ''
            ${lib.concatStringsSep "\n" allEntries}
          '';
        in
        ''
          ${network.domain} {
            hosts ${hostsFile} {
              reload 0 # the file is read-only, no need to dynamically reload it
            }
            any
            errors
            prometheus :9153
          }
        '')
      (with inventory.networks; [
        mgmt
        public
        trusted
        wg-trusted
        iot
        wg-iot
        work
        wg-work
      ]);
  };
}
