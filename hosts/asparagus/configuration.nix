{ config, lib, pkgs, ... }:
let
  mgmt-iface = "eno1";
  mgmt-address = "192.168.88.4";
  mgmt-network = "192.168.88.0";
  mgmt-gateway = "192.168.88.1";
  mgmt-netmask = "255.255.255.0";
  mgmt-prefix = 24;
in
with lib;
{
  imports = [ ./hardware-configuration.nix ];

  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.kernelParams = [
    "ip=${mgmt-address}::${mgmt-gateway}:${mgmt-netmask}:${config.networking.hostName}:${mgmt-iface}::::"
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.network = {
    enable = true;
    postCommands = ''
      echo "cryptsetup-askpass; exit" > /root/.profile
    '';
    ssh = {
      enable = true;
      hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/ssh_host_rsa_key" ];
      authorizedKeys = builtins.filter
        (key: key != "")
        (lib.splitString
          "\n"
          (builtins.readFile (import ../../data/jmbaur-ssh-keys.nix))
        );
    };
  };

  custom.common.enable = true;
  custom.deploy.enable = true;

  time.timeZone = "America/Los_Angeles";
  networking = {
    hostName = "asparagus";
    domain = "home.arpa";
    firewall.enable = true;
    nameservers = singleton mgmt-gateway;
    defaultGateway.address = mgmt-gateway;
    interfaces.${mgmt-iface} = {
      useDHCP = false;
      ipv4.addresses = [{
        address = mgmt-address;
        prefixLength = mgmt-prefix;
      }];
    };
    interfaces.wlp0s20f3.useDHCP = false;
  };

  programs.ssh.extraConfig = ''
    Host *
      IdentityFile /etc/ssh/ssh_host_rsa_key
      User root
  '';
  programs.ssh.knownHosts.kale = {
    publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCdlL4oE5WXdJG0l9Cv31vuPkCHeh1m5ciLC+1iOR3PuFZBx5vlDig6v1Th4V2rL9UMP769+0NmHXXXH92IYz0/9Bt0Sv3vwfZlVA7Bhi2m1VWhaabMSXRpJ5r0FuG/FHTcIyg2yWRaf0S2CyJ0bTMD8CkzR/W05zaK32op6SUGAE8RqSWO3I4O5j4/wPEkY4Jjfry/sDnaOdMd1gd24p+xcdHWrJLQpzpkmJCViNSN5zMXvoccx5XuV1cFIp5HOKAC1QDoZ8n0iaj3H7GJ5f3iZcCNUNIJLFNkeYWLNGFz15xgxQ/Bngl7gJmwjchCm72s3lJMpWfX589PwkBg/hrpunT44oJ9dARdZY+V9ydFqu3jjP6xDYKVduVMeUZEBSvjmsWjmXnrciDO/4vWNBi9d+2NPXT3iLjIktx7SklYj40A/jOOHog1KLD36RYYqli9SidzUQhyvzytkh2Xe/TbGTG2Yhm7+0j7aelkvtDKq/dW5lmkZx6AcI04QOBJ2O+V98MLBWixkD9KQmBQsNr9gJKwAuu6IDi2ZtmVhHmcr+zQk8o7ixeOGc7x7BjSGTSgjrRsqGBzwNFBmtBWiLPJKwjKQd5obVFE16Sdb+8uVASeK117Kj6nnJIT6OrV89lJF4+tnsgkBSlvzs3tN06DqSTs7w4sxKku9wCQOjHI/w==";
    hostNames = [ "kale" ];
  };
  programs.ssh.knownHosts.rhubarb = {
    publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDcK80Aq2G4aeUNvNIpIsYdiMMvm7KzomAe+U4ZOrq5F/Ae6v7qposPuXiM2ErQvTsgAUlWY+iFk74zPU42v2mtERYXCZynyllgljZB/HRp4zHVWoEVoXFFKZ74jsc1i708HcgzT/gXRR+md70rJGAwpB0rjsAoavkd9ScPB2pGSgXjMLazjTPvH6++g9YOPmUWg6E5+OHFqdaUoq2C8vxjOx4sUhoGuSD8UoV8E//nirBW5q0fmCvtWYI6Pe1BcEqjLZpvrvGo8C+x0CuAETGIJIriR4+EvFvuLZhxqm+2b2vUH/VZmegxnp/4WaZpAtpoKpDDYBzJqwIXiD2x8IUthr3TkV9uK2a0xDx5XEf/kZTcnlLVzAMsJA5LSjOdS0RnEyA+C9cG6god6Y22AN0KIjJg6F+0uHLUxHegi+V/1BMfG7jvQE5Dtfyc/1XiRfFlAevPGnQ7b8TOduILHHwkBiKZbQqFkQVi3KKO2D7iBP+Lhe8t7ap8xrflk/5zZh3mCGf6EFqlN5RdpIOb3TG2uXP/LHB4t7uhcwMX4Oj2pcAdsXDFcqCExKBBog8c7Zp1rOWh+UIqK7s5HjqitsLpZJZlF1NsByP5jXy+BeyQ3FdaAFIv87wCbEQ/rJPzWSV7McK1LJ31QK1en01BkdoO++TkF088cZGzMTKRYgHS5Q==";
    hostNames = [ "rhubarb" ];
  };
  nix.buildMachines = [
    {
      hostName = "kale";
      systems = [ "x86_64-linux" "aarch64-linux" "riscv64-linux" ];
      maxJobs = 24; # number of cores
      speedFactor = 10; # arbitrary
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }
  ];
  nix.distributedBuilds = true;
  # let the remote builder do the fetching over the network
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
