{ config, lib, pkgs, inventory, ... }: {
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
          (with inventory.networks; [ pubwan.id trusted.id ]);
      };
      bridge = {
        name = config.systemd.network.netdevs.bridge.netdevConfig.Name;
        networkConfig.LinkLocalAddressing = "no";
      };
      pubwan-vms = {
        name = "vm-website";
        networkConfig.Bridge =
          config.systemd.network.networks.bridge.name;
        # Each VM needs PVID and EgressUntagged to function properly
        extraConfig = ''
          [BridgeVLAN]
          PVID=${toString inventory.networks.pubwan.id}
          EgressUntagged=${toString inventory.networks.pubwan.id}
        '';
      };
    };
  };

  custom.remoteBoot = {
    enable = true;
    authorizedKeyFiles = config.custom.deployee.authorizedKeyFiles;
  };
  boot.initrd.availableKernelModules = [ "igb" ];
}
