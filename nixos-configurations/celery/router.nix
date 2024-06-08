{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];
  hardware.wirelessRegulatoryDatabase = true;

  router = {
    enable = true;
    ipv6UlaPrefix = "fd4c:ddfe:28e9::/64";
    lanInterface = config.systemd.network.netdevs."10-br0".netdevConfig.Name;
    wanInterface = "wan";
  };

  systemd.network.netdevs."10-br0".netdevConfig = {
    Name = "br0";
    Kind = "bridge";
  };

  systemd.network.networks = lib.mapAttrs' (name: value: lib.nameValuePair "10-${name}" value) (
    lib.genAttrs
      [
        "lan1"
        "lan2"
        "lan3"
        "lan4"
        "wlan0"
        "wlan1"
      ]
      (name: {
        inherit name;
        bridge = [ config.systemd.network.netdevs."10-br0".netdevConfig.Name ];
        linkConfig = {
          ActivationPolicy = "always-up";
          RequiredForOnline = false;
        };
      })
  );

  services.openssh.openFirewall = false;
  networking.firewall.interfaces.${config.router.lanInterface}.allowedTCPPorts = [ 22 ];

  environment.systemPackages = [ pkgs.iw ];

  sops.secrets = {
    ipwatch_env = { };
    wlan0.reloadUnits = [ config.systemd.services.hostapd.name ];
    wlan1.reloadUnits = [ config.systemd.services.hostapd.name ];
  };

  services.hostapd = {
    enable = true;
    radios.wlan0 = {
      countryCode = "US";
      networks.wlan0 = {
        ssid = "Silence of the LANs";
        authentication.saePasswordsFile = config.sops.secrets.wlan0.path;
        settings.ieee80211w = 2;
      };
    };
    radios.wlan1 = {
      band = "5g";
      channel = 0;
      countryCode = "US";
      wifi4.enable = false;
      wifi6.enable = true;
      networks.wlan1 = {
        ssid = "SpiderLAN";
        authentication.saePasswordsFile = config.sops.secrets.wlan1.path;
        settings.ieee80211w = 2;
      };
    };
  };
}
