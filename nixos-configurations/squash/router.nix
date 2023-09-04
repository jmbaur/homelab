{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.router.enable {
    services.usbguard.enable = true;

    sops.defaultSopsFile = ./secrets.yaml;
    sops.secrets.ipwatch_env = { };

    systemd.network.netdevs.br0.netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };

    services.ipwatch = {
      enable = true;
      interfaces = [ config.router.wanInterface ];
      hookEnvironmentFile = config.sops.secrets.ipwatch_env.path;
      filters = [ "IsGlobalUnicast" "!IsPrivate" "!IsLoopback" "!Is4In6" ];
      hooks =
        let
          updateCloudflare = recordType: ''
            ${pkgs.curl}/bin/curl \
              --silent \
              --show-error \
              --request PUT \
              --header "Content-Type: application/json" \
              --header "Authorization: Bearer ''${CF_DNS_API_TOKEN}" \
              --data '{"type":"${recordType}","name":"squash.jmbaur.com","content":"'"''${ADDR}"'","proxied":false}' \
              "https://api.cloudflare.com/client/v4/zones/''${CF_ZONE_ID}/dns_records/''${CF_RECORD_ID_${recordType}}" | ${pkgs.jq}/bin/jq
          '';
          updateCloudflareA = updateCloudflare "A";
          updateCloudflareAAAA = updateCloudflare "AAAA";
          script = pkgs.writeShellScript "update-cloudflare" ''
            if [[ "$IS_IP6" == "1" ]]; then
              ${updateCloudflareAAAA}
            elif [[ "$IS_IP4" == "1" ]]; then
              ${updateCloudflareA}
            else
              echo nothing to update
            fi
          '';
        in
        [ "internal:echo" "executable:${script}" ];
    };

    custom.wg-mesh = {
      enable = true;
      peers.beetroot = { };
      peers.carrot = { };
      firewall = {
        beetroot.allowAll = true;
        carrot.allowedTCPPorts = [
          19531 # systemd-journal-gatewayd
          9153 # coredns
          9430 # corerad
          config.services.prometheus.exporters.blackbox.port
          config.services.prometheus.exporters.node.port
        ];
      };
    };

    # Use udev for giving wireless interfaces a static name. Udev is used over
    # systemd-networkd link units since hostapd needs to start before
    # systemd-networkd, thus rendering a rename useless.
    services.udev.extraRules = ''
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="c4:4b:d1:c0:01:2f", NAME="wlan0"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="c4:4b:d1:c1:01:2f", NAME="wlan1"
    '';

    systemd.network.networks = (lib.genAttrs [ "lan1" "lan2" "lan3" "lan4" "lan5" "wlan0" "wlan1" ] (name: {
      inherit name;
      bridge = [ config.systemd.network.netdevs.br0.netdevConfig.Name ];
      linkConfig = {
        ActivationPolicy = "always-up";
        RequiredForOnline = false;
      };
    }));

    router.lanInterface = config.systemd.network.netdevs.br0.netdevConfig.Name;
    router.wanInterface = config.systemd.network.links."10-wan".linkConfig.Name;

    services.openssh.openFirewall = false;
    networking.firewall.interfaces.${config.systemd.network.networks.lan.name}.allowedTCPPorts = [ 22 ];

    environment.systemPackages = [ pkgs.iw ];

    services.hostapd = {
      enable = true;
      radios.wlan0.countryCode = "US";
      radios.wlan1 = {
        band = "5g";
        channel = 0;
        countryCode = "US";
        wifi4.enable = false;
        wifi6.enable = true;
      };
    };
  };
}
