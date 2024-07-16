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

  isCross = pkgs.stdenv.hostPlatform != pkgs.stdenv.buildPlatform;
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

        # TODO(jared): This does not work on newer kernels due to using
        # dev_base_lock.
        # boot.extraModulePackages = [ (config.boot.kernelPackages.callPackage ./nat46.nix { }) ];

        networking.firewall.allowedUDPPorts = [
          5353 # mDNS
        ];

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
                IPv6PrivacyExtensions = lib.mkIf (!config.custom.server.enable) "kernel";
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
              matchConfig.Type = "ether";
              dhcpV4Config = {
                UseDomains = "route";
                RouteMetric = 100;
              };
              networkConfig = {
                IPv6PrivacyExtensions = lib.mkIf (!config.custom.server.enable) "kernel";
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
      }
      (lib.mkIf (!config.custom.server.enable) {
        services.clatd = {
          enable = (lib.warnIf isCross "clatd does not cross-compile, disabling") (!isCross);
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

        services.networkd-dispatcher = {
          enable = true;
          rules.restart-clatd = {
            onState = [
              "routable"
              "off"
            ];
            script = # bash
              ''
                #!${pkgs.runtimeShell}
                if [[ $IFACE != "${clatIfaceName}" ]]; then
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

        systemd.network.networks."50-clatd" = {
          matchConfig.Name = clatIfaceName;
          linkConfig = {
            Unmanaged = true;
            ActivationPolicy = "manual";
          };
        };
      })
    ]
  );
}
