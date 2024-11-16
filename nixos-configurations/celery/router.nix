{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];
  hardware.wirelessRegulatoryDatabase = true;

  # TODO(jared): resolving babeld and nixos-router conflicts
  boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = lib.mkForce 1;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = lib.mkForce 1;

  router = {
    enable = true;
    lanInterface = config.systemd.network.netdevs."10-br0".netdevConfig.Name;
    wanInterface = "wan";
  };

  systemd.network.netdevs."10-br0" = {
    netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };
    # Allow multicast traffic to be sent to all ports without clients
    # registering themselves.
    #
    # TODO(jared): `bridge mdb` shows registerations,
    # but it seems disabling snooping still fixes the issue.
    bridgeConfig.MulticastSnooping = false;
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
        linkConfig.RequiredForOnline = false;
      })
  );

  services.openssh.openFirewall = false;
  networking.firewall.interfaces.${config.router.lanInterface}.allowedTCPPorts = [ 22 ];

  environment.systemPackages = [ pkgs.iw ];

  sops.secrets = {
    wlan0.reloadUnits = [ config.systemd.services.hostapd.name ];
    wlan1.reloadUnits = [ config.systemd.services.hostapd.name ];
  };

  services.hostapd = {
    enable = true;
    radios.wlan0 = {
      band = "2g";
      countryCode = "US";
      wifi4.enable = true;
      wifi5.enable = false;
      wifi6.enable = false;
      wifi7.enable = false;
      wifi4.capabilities = [
        "HT40"
        # "HT40-" # doesn't work with ACS (channel=0)
        "SHORT-GI-20"
        "SHORT-GI-40"
      ];
      networks.wlan0 = {
        ssid = "Silence of the LANs";
        settings.ieee80211w = 2;
        settings.sae_password_file = config.sops.secrets.wlan0.path;
      };
    };
    radios.wlan1 = {
      band = "5g";
      countryCode = "US";
      wifi4.enable = false;
      wifi5.enable = false;
      wifi6.enable = true;
      wifi7.enable = false;
      networks.wlan1 = {
        ssid = "SpiderLAN";
        settings.ieee80211w = 2;
        settings.sae_password_file = config.sops.secrets.wlan1.path;
      };
    };
  };
}
