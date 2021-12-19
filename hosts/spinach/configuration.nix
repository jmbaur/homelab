{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  networking.hostName = "spinach";
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.eno2.useDHCP = true;
  networking.interfaces.eno3.useDHCP = true;
  networking.interfaces.eno4.useDHCP = true;
  networking.firewall.allowedTCPPorts = [ 2222 ];
  networking.firewall.allowedUDPPorts = [ ];

  users = {
    mutableUsers = false;
    users.jared = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = "helloworld";
    };
  };

  programs.mtr.enable = true;

  services.openssh.enable = true;

  containers.dev = {
    config = import ./containers/dev.nix;
    bindMounts = { };
    allowedDevices = [{ modifier = "rw"; node = "/dev/fuse"; }];
    forwardPorts = [{ hostPort = 2222; }];
    enableTun = true;
    autoStart = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
