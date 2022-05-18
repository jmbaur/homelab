{ config, lib, ... }: {
  systemd.services.systemd-networkd-wait-online.enable = false;
  systemd.network = {
    networks = {
      wired = {
        matchConfig.Name = "en*";
        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config = {
          RouteMetric = 10;
          UseDomains = "yes";
        };
      };

      wireless = {
        matchConfig.Name = "wl*";
        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config = {
          RouteMetric = 20;
          UseDomains = "yes";
        };
      };
    };
  };

  networking = {
    useDHCP = lib.mkForce false;
    hostName = "beetroot";
    useNetworkd = true;
    wireless.iwd.enable = true;
    # wg-quick.interfaces.wg0 = {
    #   autostart = false;
    #   privateKeyFile = config.sops.secrets.wg0.path;
    #   address = [ "192.168.130.100" ];
    #   dns = [ "192.168.130.1" ];
    #   peers = [{
    #     publicKey = "68sZOobFSYwyt7ZVsQ6steLqHH/CEQQHluUr+X6y5AQ=";
    #     endpoint = "vpn.jmbaur.com:51830";
    #     allowedIPs = [ "0.0.0.0/0" "::/0" ];
    #   }];
    # };
  };
}
