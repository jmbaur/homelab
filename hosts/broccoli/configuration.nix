{ config, pkgs, ... }: {
  imports = [
    ./coredns.nix
    ./corerad.nix
    ./dhcpcd.nix
    ./dhcpd4.nix
    ./networking.nix
    ./nftables.nix
    ./hardware-configuration.nix
  ];

  custom.common.enable = true;
  custom.deploy.enable = true;

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelParams = [ "console=ttyS0,115200" "console=tty1" ];
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.wg0 = {};
    secrets.cloudflare = {
      owner = config.users.users.dhcpcd.name;
      group = config.users.users.dhcpcd.group;
    };
    secrets.he_tunnelbroker = {
      owner = config.users.users.dhcpcd.name;
      group = config.users.users.dhcpcd.group;
    };
  };

  environment.systemPackages = with pkgs; [
    conntrack-tools
    dig
    ethtool
    ipmitool
    powertop
    ppp
    tcpdump
  ];

  services = {
    avahi = {
      enable = true;
      reflector = true;
      ipv4 = true;
      ipv6 = true;
    };
    openssh = with config.networking.interfaces; {
      enable = true;
      passwordAuthentication = false;
      openFirewall = false;
      allowSFTP = false;
      listenAddresses = (
        (builtins.map
          (ifi: { port = 22; addr = ifi.address; })
          eno2.ipv4.addresses)
        ++
        (builtins.map
          (ifi: { port = 22; addr = "[" + ifi.address + "]"; })
          eno2.ipv6.addresses)
      );
    };
    iperf3.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
