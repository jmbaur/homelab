{ config, lib, ... }: {
  networking = {
    hostName = "kale";
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      interfaces.${config.systemd.network.networks.mgmt.name} = {
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
          Name = "br0";
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
        name = "enp35s0";
        DHCP = "yes";
        dhcpV4Config.ClientIdentifier = "mac";
      };
      trunk = {
        name = "enp1s0";
        networkConfig.Bridge = config.systemd.network.netdevs.bridge.netdevConfig.Name;
        # Support for trunked VLANs
        extraConfig = lib.concatMapStrings
          (vlan: ''
            [BridgeVLAN]
            VLAN=${toString vlan}
          '')
          ([ /* TODO(jared): fill in VLAN IDs here */ ]);
      };
      bridge = {
        name = config.systemd.network.netdevs.bridge.netdevConfig.Name;
        networkConfig.LinkLocalAddressing = "no";
      };
    };
  };

  custom.remoteBoot = {
    enable = true;
    authorizedKeyFiles = config.custom.deployee.authorizedKeyFiles;
  };
  boot.initrd.availableKernelModules = [ "igb" ];
}
