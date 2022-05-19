{ config, lib, pkgs, ... }: {
  networking = {
    hostName = "kale";
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      interfaces.${config.systemd.network.networks.mgmt.matchConfig.Name} = {
        allowedTCPPorts = config.services.openssh.ports ++ [
          config.services.prometheus.exporters.node.port
        ];
      };
    };
  };

  systemd.network = {
    netdevs = {
      bridge = {
        netdevConfig = {
          Name = "virbr0";
          Kind = "bridge";
        };
        extraConfig = ''
          [Bridge]
          DefaultPVID=none
          VLANFiltering=yes
        '';
      };
    };
    networks = {
      mgmt = {
        matchConfig.Name = "enp35s0";
        networkConfig.DHCP = "yes";
        dhcpV4Config.ClientIdentifier = "mac";
      };
      data = {
        matchConfig.Name = "enp1s0";
        bridge = [ config.systemd.network.networks.bridge.matchConfig.Name ];
      };
      bridge = {
        matchConfig.Name = config.systemd.network.netdevs.bridge.netdevConfig.Name;
        linkConfig.RequiredForOnline = false;
        extraConfig = ''
          [BridgeVLAN]
          VLAN=30
        '';
      };
      microvms = {
        matchConfig.Name = "vm-*";
        networkConfig.Bridge =
          config.systemd.network.networks.bridge.matchConfig.Name;
        extraConfig = ''
          [BridgeVLAN]
          PVID=30
        '';
      };
    };
  };
}
