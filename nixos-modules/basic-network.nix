{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.basicNetwork;

  hasWireless = with config.networking.wireless; enable || iwd.enable;

  clatIfaceName = "clat0";

  isNetworkManager = config.networking.networkmanager.enable;
in
{
  options.custom.basicNetwork = {
    enable = lib.mkEnableOption "basic network setup";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        networking.useDHCP = false;

        services.resolved.enable = true;

        services.clatd = {
          enable = true;
          settings = {
            clat-dev = clatIfaceName;
            # NOTE: Perl's Net::DNS resolver does not seem to work well querying
            # for AAAA records to systemd-resolved's default IPv4 bind address
            # (127.0.0.53), so we add an IPv6 listener address to systemd-resolved
            # and tell clatd to use that instead.
            dns64-servers = lib.mkIf config.services.resolved.enable "::1";
          };
        };

        # Allow clatd to find dns server. See comment above.
        services.resolved.extraConfig = ''
          DNSStubListenerExtra=::1
        '';
      }
      (lib.mkIf (!isNetworkManager) {
        networking.useNetworkd = true;
        networking.firewall.allowedUDPPorts = [
          5353 # mDNS
          5355 # LLMNR
        ];

        systemd.network.wait-online.enable = !hasWireless;
        systemd.network = {
          enable = true;
          networks = {
            wireless = lib.mkIf hasWireless {
              DHCP = "yes";
              matchConfig.Type = "wlan";
              dhcpV4Config = {
                UseDomains = "route";
                RouteMetric = 2048;
              };
              ipv6AcceptRAConfig = {
                UseDomains = "route";
                RouteMetric = 2048;
              };
              networkConfig = {
                IPv6PrivacyExtensions = "kernel";
                Domains = "~.";
                MulticastDNS = true;
              };
            };
            wired = {
              DHCP = "yes";
              matchConfig.Type = "ether";
              dhcpV4Config = {
                UseDomains = "route";
                RouteMetric = 1024;
              };
              ipv6AcceptRAConfig = {
                UseDomains = "route";
                RouteMetric = 1024;
              };
              networkConfig = {
                IPv6PrivacyExtensions = "kernel";
                Domains = "~.";
                MulticastDNS = true;
              };
            };
          };
        };

        services.networkd-dispatcher = {
          enable = true;
          rules.restart-clatd = {
            onState = [
              "routable"
              "off"
            ];
            script = ''
              #!${pkgs.runtimeShell}
              if [[ $IFACE != "${clatIfaceName}" ]]; then
                systemctl restart clatd
              fi
            '';
          };
        };

        systemd.network.networks."50-clatd" = {
          matchConfig.Name = clatIfaceName;
          linkConfig = {
            Unmanaged = true;
            ActivationPolicy = "manual";
          };
        };
      })
      (lib.mkIf isNetworkManager {
        networking.networkmanager = {
          dns = "systemd-resolved";
          wifi.backend = "iwd";
          dispatcherScripts = [
            {
              type = "basic";
              # Adapted from https://github.com/toreanderson/clatd/blob/04062b282dfa55ea123b94c6d354525fe6670324/scripts/clatd.networkmanager
              source = pkgs.writeShellScript "clatd-dispatch-script" ''
                [ "$DEVICE_IFACE" = "${clatIfaceName}" ] && exit 0
                [ "$2" != "up" ] && [ "$2" != "down" ] && exit 0
                ${lib.getExe' config.systemd.package "systemctl"} --no-block restart clatd.service
              '';
            }
          ];
        };
      })
    ]
  );
}
