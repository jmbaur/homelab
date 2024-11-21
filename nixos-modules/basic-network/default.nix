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
        networking.useDHCP = false;

        # Randomize wireless card's MAC address for each connected network.
        networking.wireless.iwd.settings.General.AddressRandomization = "network";

        services.resolved.enable = true;

        # Allow clatd to find dns server. See comment above.
        services.resolved.extraConfig = ''
          DNSStubListenerExtra=::1
        '';

        networking.firewall.allowedUDPPorts = [
          5353 # mDNS
        ];
      }

      (lib.mkIf
        (
          # Set by some desktop modules (e.g. gnome)
          !config.networking.networkmanager.enable
        )
        {
          # TODO(jared): This does not work on newer kernels due to using
          # dev_base_lock.
          # boot.extraModulePackages = [ (config.boot.kernelPackages.callPackage ./nat46.nix { }) ];

          networking.useNetworkd = true;

          systemd.network.wait-online.enable = !hasWireless;

          systemd.network = {
            enable = true;
            networks = {
              "50-wireless" = lib.mkIf hasWireless {
                DHCP = "yes";
                matchConfig.Type = "wlan";
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
                  Token = "prefixstable";
                  UseDomains = "route";
                  RouteMetric = 100;
                  UsePREF64 = true;
                };
              };
              "50-wired" = {
                DHCP = "yes";
                matchConfig.Type = "ether";
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
                  Token = "prefixstable";
                  UseDomains = "route";
                  RouteMetric = 100;
                  UsePREF64 = true;
                };
              };
            };
          };

          services.networkd-dispatcher = {
            enable = config.services.clatd.enable;
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

          systemd.services.tinyclatd = {
            # TODO(jared): finish and enable
            enable = false;

            description = "464XLAT CLAT daemon";
            documentation = [ "man:clatd(8)" ];
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            startLimitIntervalSec = 0;

            serviceConfig = {
              ExecStart = lib.getExe pkgs.tinyclatd;

              # Hardening
              CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectProc = "invisible";
              ProtectSystem = true;
              RestrictAddressFamilies = [
                "AF_INET"
                "AF_INET6"
                "AF_NETLINK"
              ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              SystemCallArchitectures = "native";
              SystemCallFilter = [
                "@network-io"
                "@system-service"
                "~@privileged"
                "~@resources"
              ];
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
            dns64-servers = lib.mkIf config.services.resolved.enable "::1";
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
