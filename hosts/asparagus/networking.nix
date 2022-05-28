{ pkgs, config, lib, ... }: {
  networking = {
    hostName = "asparagus";
    useDHCP = lib.mkForce false;
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;
    netdevs = {
      mgmt = {
        netdevConfig = { Name = "mgmt"; Kind = "vlan"; };
        vlanConfig.Id = 88;
      };
      trusted = {
        netdevConfig = { Name = "trusted"; Kind = "vlan"; };
        vlanConfig.Id = 30;
      };
    };
    networks = {
      trunk = {
        matchConfig.Name = "enp4s0";
        networkConfig.LinkLocalAddressing = "no";
        vlan = map
          (name: config.systemd.network.netdevs.${name}.netdevConfig.Name)
          [ "mgmt" "trusted" ];
      };
      mgmt = {
        matchConfig.Name =
          config.systemd.network.netdevs.mgmt.netdevConfig.Name;
        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = true;
          DefaultRouteOnDevice = false;
        };
        dhcpV4Config = {
          UseDomains = "yes";
          ClientIdentifier = "mac";
        };
      };
      trusted = {
        matchConfig.Name =
          config.systemd.network.netdevs.trusted.netdevConfig.Name;
        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config = {
          UseDomains = "yes";
          ClientIdentifier = "mac";
        };
      };
    };
  };

  # Support for tagged interface in the initrd
  boot.initrd.availableKernelModules = [
    "8021q"
    "igb"
    "mlx4_core"
    "mlx4_en"
  ];
  boot.initrd.network.postCommands = ''
    ${pkgs.iproute2}/bin/ip link add link ${config.systemd.network.networks.trunk.matchConfig.Name} name mgmt type vlan id 88
    ${pkgs.iproute2}/bin/ip link set dev mgmt up
  '';
}
