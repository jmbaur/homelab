{ pkgs, config, lib, ... }: {
  networking = {
    hostName = "asparagus";
    useDHCP = lib.mkForce false;
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;
    networks = {
      enp4s0 = {
        matchConfig.Name = "enp4s0";
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

  custom.remoteBoot = {
    enable = true;
    interface = config.systemd.network.networks.enp4s0.matchConfig.Name;
  };
  boot.initrd.availableKernelModules = [ "mlx4_core" "mlx4_en" ];
}
