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
        debug = 2;
        # TODO(jared): The perl DNS resolver does not seem to work well without
        # this, but this obviously won't work outside of the home network.
        dns64-servers = [ "fd4c:ddfe:28e9::1" ];
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

    systemd.network.networks."50-clatd" = lib.mkIf isNetworkd {
      matchConfig.Name = ifaceName;
      linkConfig = {
        Unmanaged = true;
        ActivationPolicy = "manual";
      };
    };
  };
}
