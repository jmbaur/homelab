{ config, lib, ... }: {
  config = lib.mkIf config.router.enable {
    systemd.network.netdevs.br0.netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };

    systemd.network.networks = (lib.genAttrs
      [ "lan1" "lan2" "lan3" "lan4" "lan5" "wlp1s0" "wlan1" ]
      (name: {
        inherit name;
        bridge = [ config.systemd.network.netdevs.br0.netdevConfig.Name ];
        linkConfig = {
          ActivationPolicy = "always-up";
          RequiredForOnline = "no";
        };
      }));

    router.lanInterface = config.systemd.network.netdevs.br0.netdevConfig.Name;
    router.wanInterface = config.systemd.network.links."10-wan".linkConfig.Name;

    networking.firewall.interfaces.${config.systemd.network.networks.lan.name}.allowedTCPPorts = [ 22 ];
  };
}
