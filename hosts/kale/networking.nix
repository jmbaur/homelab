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
        matchConfig.Name = "enp35s0";
        networkConfig.DHCP = "yes";
        dhcpV4Config.ClientIdentifier = "mac";
      };
      trunk = {
        matchConfig.Name = "enp1s0";
        networkConfig.Bridge = config.systemd.network.netdevs.bridge.netdevConfig.Name;
        # Support for all trunked VLANs
        extraConfig = lib.concatMapStrings
          (vlan: ''
            [BridgeVLAN]
            VLAN=${toString vlan}
          '') [ 10 20 30 40 50 ];
      };
      bridge = {
        matchConfig.Name = config.systemd.network.netdevs.bridge.netdevConfig.Name;
        networkConfig.LinkLocalAddressing = "no";
      };
      trusted-vms = {
        matchConfig.Name = lib.concatStringsSep " " [ "vm-test" ];
        networkConfig.Bridge =
          config.systemd.network.networks.bridge.matchConfig.Name;
        # Each VM needs PVID and EgressUntagged to function properly
        extraConfig = ''
          [BridgeVLAN]
          PVID=30
          EgressUntagged=30
        '';
      };
    };
  };

  custom.remoteBoot.enable = true;
  boot.initrd.availableKernelModules = [ "igb" ];
}
