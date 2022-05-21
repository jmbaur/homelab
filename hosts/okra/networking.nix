{ config, lib, pkgs, ... }: {
  services.mullvad-vpn.enable = true;

  networking = {
    useDHCP = lib.mkForce false;
    hostName = "okra";
    useNetworkd = true;
    wireless.iwd.enable = true;
  };

  systemd.services.systemd-networkd-wait-online.enable = false;
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
