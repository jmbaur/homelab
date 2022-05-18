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
    netdevs =
      let
        mkVlanNetdev = name: id: {
          netdevConfig = { Name = name; Kind = "vlan"; };
          vlanConfig.Id = id;
        };
      in
      {
        pubwan = mkVlanNetdev "pubwan" 10;
        publan = mkVlanNetdev "publan" 20;
        trusted = mkVlanNetdev "trusted" 30;
        iot = mkVlanNetdev "iot" 40;
        guest = mkVlanNetdev "guest" 50;
        mgmt = mkVlanNetdev "mgmt" 88;

        virbr0 = {
          netdevConfig = {
            Name = "virbr0";
            Kind = "bridge";
          };
          extraConfig = ''
            [Bridge]
            DefaultPVID=1
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
      virbr0 = {
        matchConfig.Name = config.systemd.network.netdevs.virbr0.netdevConfig.Name;
        linkConfig.RequiredForOnline = false;
        networkConfig = {
          VLAN = builtins.map
            (name: config.systemd.network.netdevs.${name}.netdevConfig.Name)
            [ "pubwan" "publan" "trusted" "iot" "guest" "mgmt" ];
        };
        extraConfig = ''
          [BridgeVLAN]
          VLAN=1

          [BridgeVLAN]
          VLAN=10
        '';
      };
      microvm-eth0 = {
        matchConfig.Name = "vm-*";
        networkConfig.Bridge = "virbr0";
      };
    };
  };
}
