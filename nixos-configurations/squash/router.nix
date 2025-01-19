{
  config,
  lib,
  pkgs,
  utils,
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
        "lan5"
        "lan6"
        "wlp1s0"
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
    wlp1s0.reloadUnits = [ config.systemd.services.hostapd.name ];
    wlan1.reloadUnits = [ config.systemd.services.hostapd.name ];
  };

  # Override the `after` and `bindsTo` for hostapd since the MT7915 wireless
  # card we are using here seems to have some special bringup where the second
  # wireless phy is bound to the first one in such a way that systemd doesn't
  # recognize it as a unique device. This prevents hostapd from failing to
  # start due to sys-subsystem-net-devices-wlan1.device no longer timing out.
  # See https://github.com/nixos/nixpkgs/blob/22bd84a21bd7c4ca569e5bc4db9fd9177d9b4606/nixos/modules/services/networking/hostapd.nix#L1206
  systemd.services.hostapd = {
    after = lib.mkForce (
      map (radio: "sys-subsystem-net-devices-${utils.escapeSystemdPath radio}.device") (
        lib.filter (radio: radio != "wlan1") (lib.attrNames config.services.hostapd.radios)
      )
    );
    bindsTo = lib.mkForce (
      map (radio: "sys-subsystem-net-devices-${utils.escapeSystemdPath radio}.device") (
        lib.filter (radio: radio != "wlan1") (lib.attrNames config.services.hostapd.radios)
      )
    );
  };

  services.hostapd = {
    enable = true;
    radios.wlp1s0 = {
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
      networks.wlp1s0 = {
        ssid = "Silence of the LANs";
        authentication = {
          mode = "wpa3-sae-transition";
          wpaPasswordFile = config.sops.secrets.wlp1s0.path;
          saePasswordsFile = config.sops.secrets.wlp1s0.path;
        };
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
        authentication = {
          mode = "wpa3-sae-transition";
          wpaPasswordFile = config.sops.secrets.wlan1.path;
          saePasswordsFile = config.sops.secrets.wlan1.path;
        };
      };
    };
  };
}
