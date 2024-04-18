{
  config,
  lib,
  pkgs,
  ...
}:

let
  ifaceName = "clat0";

  isNetworkd = config.networking.useNetworkd;

  clatdConfig =
    (pkgs.formats.keyValue { listToValue = lib.concatMapStringsSep "," toString; }).generate
      "clatd.conf"
      {
        clat-dev = ifaceName;
        # NOTE: Perl's Net::DNS resolver does not seem to work well querying
        # for AAAA records to systemd-resolved's default IPv4 bind address
        # (127.0.0.53), so we add an IPv6 listener address to systemd-resolved
        # and tell clatd to use that instead.
        dns64-servers = lib.optionals config.services.resolved.enable [ "::1" ];
      };
in
{
  options.services.clatd.enable = lib.mkEnableOption "clatd";
  config = lib.mkIf config.services.clatd.enable {
    services.networkd-dispatcher = {
      enable = true;
      rules.restart-clatd = {
        onState = [
          "routable"
          "off"
        ];
        script = ''
          #!${pkgs.runtimeShell}
          if [[ $IFACE != "${ifaceName}" ]]; then
            systemctl restart clatd
          fi
        '';
      };
    };

    systemd.services.clatd = {
      after = [
        "modprobe@tun.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        ExecStart = toString [
          (lib.getExe pkgs.clatd)
          "-c"
          clatdConfig
        ];
        DynamicUser = true;
        PrivateTmp = true;
        TemporaryFileSystem = [ "/" ];
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
        RestrictAddressFamilies = [
          "AF_NETLINK"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = [ "net" ];
        SystemCallFilter = [ "@system-service" ];
      };
      wantedBy = [ "multi-user.target" ];
    };

    services.resolved.extraConfig = ''
      DNSStubListenerExtra=::1
    '';

    systemd.network.networks."50-clatd" = lib.mkIf isNetworkd {
      matchConfig.Name = ifaceName;
      linkConfig = {
        Unmanaged = true;
        ActivationPolicy = "manual";
      };
    };
  };
}
