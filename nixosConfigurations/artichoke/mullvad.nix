{ config, secrets, ... }: {
  systemd.network.netdevs.wg-mullvad = {
    netdevConfig = {
      Kind = "wireguard";
      Name = "wg-mullvad";
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets."wg/mullvad".path;
      RouteTable = "off"; # don't setup routes for allowed IPs
    };
    wireguardPeers = [{
      wireguardPeerConfig = {
        AllowedIPs = [ "0.0.0.0/0" "::0/0" ];
        Endpoint = "${secrets.networking.mullvad.endpoint}";
        PublicKey = "dClWdBHZT7dwqXzIRzit6CIaJYAFtTL/yYZ8Knj8Cjk=";
        PersistentKeepalive = 25;
      };
    }];
  };

  systemd.network.networks.wg-mullvad = {
    name = config.systemd.network.netdevs.wg-mullvad.netdevConfig.Name;
    address = [ "10.65.20.58/32" "fc00:bbbb:bbbb:bb01::2:1439/128" ];
    dns = [ "10.64.0.1" ];
    routes = [
      # {
      #   routeConfig = {
      #     Gateway = "0.0.0.0";
      #     Source = inventory.networks.iot.networkIPv4Cidr;
      #   };
      # }
      # {
      #   routeConfig = {
      #     Gateway = "::";
      #     Source = inventory.networks.iot.networkGuaCidr;
      #   };
      # }
    ];
  };
}
