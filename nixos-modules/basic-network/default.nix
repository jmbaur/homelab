{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.basicNetwork;

  hasWireless = with config.networking.wireless; enable || iwd.enable;
in
{
  options.custom.basicNetwork.enable = lib.mkEnableOption "basic network setup";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # Randomize wireless card's MAC address for each connected network.
        networking.wireless.iwd.settings.General.AddressRandomization = "network";

        services.resolved.enable = true;

        networking.firewall.allowedUDPPorts = [
          5353 # mDNS
        ];
      }

      (lib.mkIf (!config.systemd.network.enable) {
        # Allow clatd to find dns server. See comment
        # next to clatd config. This is only needed if
        # systemd-networkd is not enabled since clatd has
        # special integration for obtaining the PREF64
        # prefix from systemd-networkd.
        services.resolved.extraConfig = lib.mkIf config.services.clatd.enable ''
          DNSStubListenerExtra=::1
        '';
      })

      (lib.mkIf
        (
          # Set by some desktop modules (e.g. gnome)
          !config.networking.networkmanager.enable
        )
        {
          networking.useNetworkd = true;

          systemd.network.wait-online.enable = !hasWireless;

          systemd.network = {
            enable = true;
            networks = {
              "50-wireless" = lib.mkIf hasWireless {
                DHCP = "yes";
                matchConfig.WLANInterfaceType = "station";
                dhcpV4Config = {
                  UseDomains = "route";
                  RouteMetric = 600;
                };
                networkConfig = {
                  IPv6PrivacyExtensions = !config.custom.server.enable;
                  IPv6LinkLocalAddressGenerationMode = "stable-privacy";
                  Domains = "~.";
                  MulticastDNS = true;
                };
                ipv6AcceptRAConfig = {
                  UseDomains = "route";
                  RouteMetric = 100;
                  UsePREF64 = true;
                };
              };
              "50-wired" = {
                DHCP = "yes";
                matchConfig = {
                  Type = "ether";
                  Kind = "!*"; # physical interfaces have no kind
                };
                dhcpV4Config = {
                  UseDomains = "route";
                  RouteMetric = 100;
                };
                networkConfig = {
                  IPv6PrivacyExtensions = !config.custom.server.enable;
                  IPv6LinkLocalAddressGenerationMode = "stable-privacy";
                  Domains = "~.";
                  MulticastDNS = true;
                };
                ipv6AcceptRAConfig = {
                  UseDomains = "route";
                  RouteMetric = 100;
                  UsePREF64 = true;
                };
              };
            };
          };

          services.networkd-dispatcher = {
            inherit (config.services.clatd) enable;
            rules.restart-clatd = {
              onState = [
                "routable"
                "off"
              ];
              script = ''
                #!${pkgs.runtimeShell}
                if [[ $IFACE != "${config.services.clatd.settings.clat-dev or "clat"}" ]]; then
                  systemctl restart clatd
                fi
              '';
            };
          };
        }
      )
      (lib.mkIf (!config.custom.server.enable) {
        services.clatd = {
          enable = true;
          settings = {
            clat-dev = "clat0";
            # NOTE: Perl's Net::DNS resolver does not seem to work well querying
            # for AAAA records to systemd-resolved's default IPv4 bind address
            # (127.0.0.53), so we add an IPv6 listener address to systemd-resolved
            # and tell clatd to use that instead.
            dns64-servers = lib.mkIf (!config.systemd.network.enable && config.services.resolved.enable) "::1";
          };
        };

        systemd.network.networks."50-clatd" = {
          matchConfig.Name = config.services.clatd.settings.clat-dev or "clat";
          linkConfig = {
            Unmanaged = true;
            ActivationPolicy = "manual";
          };
        };
      })
    ]
  );
}
