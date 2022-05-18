{ config, lib, pkgs, ... }: {
  services.mullvad-vpn.enable = true;

  networking = {
    useDHCP = lib.mkForce false;
    hostName = "okra";
    useNetworkd = true;
    wireless.enable = true;
  };

  systemd.network.networks.wireless = {
    matchConfig.Name = "wl*";
    networkConfig = {
      DHCP = "yes";
      IPv6PrivacyExtensions = true;
    };
    dhcpV4Config = {
      UseDomains = "yes";
      ClientIdentifier = "mac";
    };
  };

}
