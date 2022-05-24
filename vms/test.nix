{ config, lib, pkgs, ... }: {
  system.stateVersion = "22.05";
  networking = {
    hostName = "test";
    useNetworkd = true;
  };
  systemd.network.networks.en = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "yes";
    dhcpV4Config.ClientIdentifier = "mac";
  };
  virtualisation.podman.enable = true;
  security.sudo.wheelNeedsPassword = false;
  services.openssh.enable = true;
  users.mutableUsers = false;
  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ (import ../data/jmbaur-ssh-keys.nix) ];
  };
  microvm = {
    hypervisor = "qemu";
    mem = 2048;
    vcpu = 2;
    shares = [{
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    }];
    interfaces = [{
      type = "tap";
      id = "vm-" + config.networking.hostName;
      mac = "b4:b6:76:00:00:01";
    }];
  };
}
