{ config, lib, pkgs, ... }:
let
  wg = import ../../nixos-modules/mesh-network/inventory.nix;
in
{
  config = lib.mkIf config.router.enable {
    sops.defaultSopsFile = ./secrets.yaml;
    sops.secrets.wg0 = { mode = "0640"; group = config.users.groups.systemd-network.name; };

    systemd.network.netdevs.br0.netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };

    services.ipwatch = {
      enable = true;
      interfaces = [ config.router.wanInterface ];
      filters = [ "IsGlobalUnicast" "!IsPrivate" "!IsLoopback" "!Is4In6" ];
    };

    custom.wg-mesh = {
      enable = true;
      peers.beetroot = { };
      peers.rhubarb = { };
      firewall = {
        trustedIPs = [ wg.beetroot.ip ];
        ips."${wg.carrot.ip}".allowedTCPPorts = [
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

    # The hostapd nixos module uses gnu coreutils' `cat`, which uses the
    # fadvise64_64 system call, which does not work on armv7 with this module
    # (using SystemCallFilter) for some reason (see
    # https://github.com/systemd/systemd/issues/28350). This fixes the issue by
    # placing busybox in the service's PATH before coreutils. Busybox's `cat`
    # does not use fadvise64_64, so this works fine for now.
    # PR for fix: https://github.com/systemd/systemd/pull/28351
    systemd.services.hostapd.path = lib.mkBefore [ pkgs.busybox ];

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
