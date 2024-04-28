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

  isNetworkd = config.networking.useNetworkd;
in
{
  options.custom.basicNetwork = {
    enable = lib.mkEnableOption "basic network setup";
  };

  config = lib.mkIf cfg.enable {
    services.resolved.enable = true;

    networking.useDHCP = false;

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

    # TODO(jared): remove when https://github.com/NixOS/nixpkgs/pull/305844 is finalized
    systemd.services.clatd.wants = [ "network-online.target" ];

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

    # Allow clatd to find dns server
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
        script = ''
          #!${pkgs.runtimeShell}
          if [[ $IFACE != "${clatIfaceName}" ]]; then
            systemctl restart clatd
          fi
        '';
      };
    };

    systemd.network.networks."50-clatd" = lib.mkIf isNetworkd {
      matchConfig.Name = clatIfaceName;
      linkConfig = {
        Unmanaged = true;
        ActivationPolicy = "manual";
      };
    };
  };
}
