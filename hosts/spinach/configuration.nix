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
  networking.interfaces.eno2.useDHCP = false;
  networking.interfaces.eno3.useDHCP = false;
  networking.interfaces.eno4.useDHCP = false;
  # networking.interfaces.eno2.ipv4.addresses = mkForce [ ];
  # networking.macvlans.mv-eno2-host = {
  #   interface = "eno2";
  #   mode = "bridge";
  # };
  # networking.interfaces.mv-eno2-host = {
  #   ipv4.addresses = [{ address = "192.168.1.60"; prefixLength = 24; }];
  # };
  # networking.firewall.allowedTCPPorts = [ ];
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
    # bindMounts = {
    #   "/run/podman/podman.sock" = {
    #     hostPath = "/run/podman/podman.sock";
    #     isReadOnly = false;
    #   };
    # };
    # allowedDevices = [{ modifier = "rwm"; node = "/dev/fuse"; }];
    # extraFlags = [ "--system-call-filter=add_key" "--system-call-filter=keyctl" ];
    # additionalCapabilities = [ "CAP_MKNOD" ];
    # forwardPorts = [{ hostPort = 2222; }]; # container port = host port, if not specified
    # enableTun = true;
    # macvlans = [ "eno2" ];
    # privateNetwork = true;
    autoStart = true;
  };

  virtualisation.podman.enable = true;
  # systemd.services.podman = {
  #   systemConfig = {
  #     DynamicUser = "yes";
  #     ExecStart = "${pkgs.podman}/bin/podman system service";
  #   };
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
