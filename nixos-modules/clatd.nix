{
  config,
  lib,
  pkgs,
  ...
}:

let
  ifaceName = "clat0";

  isNetworkd = config.networking.useNetworkd;
in
{
  options.services.clatd.enable = lib.mkEnableOption "clatd";
  config = lib.mkIf config.services.clatd.enable {
    systemd.services.clatd = {
      after = [
        "modprobe@tun.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      unitConfig = {
        StartLimitIntervalSec = 5;
      };
      serviceConfig = {
        ExecStart = toString [
          (lib.getExe pkgs.clatd)
          "clat-dev=${ifaceName}"
          "debug=1"
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
