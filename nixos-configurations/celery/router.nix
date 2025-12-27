{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    attrValues
    concatStringsSep
    ;
in
{
  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];
  hardware.wirelessRegulatoryDatabase = true;

  services.iperf3 = {
    enable = true;
    openFirewall = false;
  };

  services.openssh.openFirewall = false;

  custom.ddns = {
    enable = true;
    interface = config.router.wanInterface;
    domain = "jmbaur.com";
  };

  custom.yggdrasil.allKnownPeers.allowedTCPPorts = [ config.services.iperf3.port ];

  networking.firewall = {
    allowedTCPPorts = [ 443 ];
    interfaces.${config.router.lanInterface}.allowedTCPPorts = [
      22
      9001
    ];

    extraForwardRules =
      let
        interfaceIDs = attrValues (import ../../nixos-modules/server/network.nix { inherit lib; });
      in
      ''
        iifname ${config.router.wanInterface} ip6 daddr & ffff:ffff:ffff:ffff:: @lan-gua-prefix ip6 daddr & ::ffff:ffff:ffff:ffff == { ${concatStringsSep ", " interfaceIDs} } accept comment "forward to server"
      '';
  };

  # Add an nftables set for updating when the GUA prefix on WAN changes
  networking.nftables.tables."nixos-fw".content = ''
    set lan-gua-prefix {
      comment "LAN GUA prefixes"
      type ipv6_addr
      flags interval
      auto-merge
      elements = { 2000::/3 }
    }
  '';

  systemd.services.wan-update-firewall = {
    serviceConfig.Restart = "on-failure";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    wants = [ "network.target" ];
    path = [
      config.systemd.package
      pkgs.ipwatch
      pkgs.jq
      pkgs.networkd-dhcpv6-client-prefix
      pkgs.nftables
    ];
    script = ''
      ipwatch -hook ${config.router.wanInterface}:${
        concatStringsSep "," [
          "!IsPrivate"
          "Is6"
          "IsGlobalUnicast"
        ]
      } | while read -r json_line; do
        address=$(echo "$json_line" | jq -r '.address')
        prefixlen=$(echo "$json_line" | jq -r '.prefixlen')
        readarray new_gua_lan_prefixes <<< $(networkctl status --json=short ${config.router.wanInterface} | networkd-dhcpv6-client-prefix)
        echo "New GUA LAN prefixes: ''${new_gua_lan_prefixes[@]}"
        nft flush set inet nixos-fw "lan-gua-prefix"
        nft add element inet nixos-fw "lan-gua-prefix" { "$(printf "%s," ''${new_gua_lan_prefixes[@]})" }
      done
    '';
  };

  services.yggdrasil.settings = {
    Listen = [ "tls://[::]:443" ];
    MulticastInterfaces = [
      {
        Regex = config.router.lanInterface;
        Beacon = true;
        Listen = true;
        Port = 9001;
      }
    ];
  };

  router = {
    enable = true;
    lanInterface = config.systemd.network.netdevs."10-br0".netdevConfig.Name;
    wanInterface = "wan";
    dns.upstreamProvider = "quad9";
  };

  systemd.network.netdevs."10-br0".netdevConfig = {
    Name = "br0";
    Kind = "bridge";
  };

  systemd.network.networks = lib.mapAttrs' (name: value: lib.nameValuePair "10-${name}" value) (
    lib.genAttrs
      [
        "lan0"
        "lan1"
        "lan2"
        "lan3"
      ]
      (name: {
        inherit name;
        bridge = [ config.router.lanInterface ];
        linkConfig.RequiredForOnline = false;
      })
  );

  environment.systemPackages = [
    pkgs.iw
    pkgs.mac-vendor-lookup
  ];

  sops.secrets = {
    wlan0.reloadUnits = [ config.systemd.services.hostapd.name ];
    wlan1.reloadUnits = [ config.systemd.services.hostapd.name ];
  };

  services.hostapd = {
    enable = true;
    radios.wlan0 = {
      settings = {
        bridge = config.router.lanInterface;
      };
      networks.wlan0 = {
        ssid = "Silence of the LANs";
        # NOTE: Add three authentication mechanisms to allow older
        # devices that only support wpa2-sha1 to connect.
        settings.wpa_key_mgmt = lib.mkForce "WPA-PSK WPA-PSK-SHA256 SAE";
        authentication = {
          mode = "wpa2-sha256";
          wpaPasswordFile = config.sops.secrets.wlan0.path;
          saePasswordsFile = config.sops.secrets.wlan0.path;
        };
      };
    };
    radios.wlan1 = {
      settings.bridge = config.router.lanInterface;
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
