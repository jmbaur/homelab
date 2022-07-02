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
        name = "enp4s0";
        DHCP = "yes";
        networkConfig.IPv6PrivacyExtensions = "kernel";
        dhcpV4Config = {
          UseDomains = "yes";
          ClientIdentifier = "mac";
        };
      };
    };
  };

  custom.remoteBoot.enable = false;
  boot.initrd.availableKernelModules = [ "igb" "mlx4_core" "mlx4_en" ];
}
