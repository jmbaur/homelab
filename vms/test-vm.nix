{ config, lib, pkgs, ... }: {
  networking.hostName = "test-vm";
  system.stateVersion = "22.05";
  security.sudo.wheelNeedsPassword = false;
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
      id = config.networking.hostName;
      mac = "bb:ec:af:8a:b2:e7";
    }];
  };
}
