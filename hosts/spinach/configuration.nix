{ config, lib, pkgs, ... }:
with lib;
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  networking.hostName = "spinach";
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.eno2 = {
    ipv4.addresses = mkForce [ ];
    ipv6.addresses = mkForce [ ];
  };
  networking.macvlans.mv-eno2-host = {
    interface = "eno2";
    mode = "bridge";
  };
  networking.firewall.allowedTCPPorts = [ 2049 /* nfs */ ];
  networking.firewall.allowedUDPPortRanges = [{
    from = 60000;
    to = 61000;
  }];
  # networking.firewall.allowedUDPPorts = [ ];

  security.sudo.enable = true; # TODO(jared): delete me

  users = {
    mutableUsers = false;
    users.jared = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = "helloworld";
    };
  };

  programs.mtr.enable = true;

  containers.dev = {
    config = import ./containers/dev.nix;
    autoStart = true;
    privateNetwork = true;
    macvlans = [ "eno2" ];
    forwardPorts = [{ hostPort = 2222; /* ssh */ }];
    enableTun = true;
    allowedDevices = [{ modifier = "rwm"; node = "/dev/fuse"; }];
    bindMounts."/dev/fuse".hostPath = "/dev/fuse";
  };

  containers.kodi = {
    config = import ./containers/kodi.nix;
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    macvlans = [ "eno2" ];
    bindMounts."/mnt/kodi".hostPath = "/data/kodi";
    forwardPorts = [{ hostPort = 2049; /* nfs */ }];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
