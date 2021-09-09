# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:
let hosts = import ../hosts.nix;
in {
  imports = [
    ../../hardware-configuration.nix
    ../../roles/common.nix
    "${
      builtins.fetchGit {
        url = "https://github.com/NixOS/nixos-hardware.git";
        rev = "eb889532fef2cb73071436842ae2ca0ed2d011aa";
        ref = "master";
      }
    }/pcengines/apu"
    ./dhcpd4.nix
    ./dhcpcd.nix
    ./coredns.nix
    ./nftables.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
  boot.kernelParams = [ "console=ttyS0,115200" "console=tty1" ];
  # boot.loader.grub.extraConfig = ''
  #   serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
  #   terminal_input --append serial
  #   terminal_output --append serial
  # '';

  boot.kernel.sysctl = {
    # if you use ipv4, this is all you need
    "net.ipv4.conf.all.forwarding" = true;

    # If you want to use it for ipv6
    "net.ipv6.conf.all.forwarding" = true;

    # source: https://github.com/mdlayher/homelab/blob/master/nixos/routnerr-2/configuration.nix#L52
    # By default, not automatically configure any IPv6 addresses.
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;

    # On WAN, allow IPv6 autoconfiguration and tempory address use.
    "net.ipv6.conf.enp1s0.accept_ra" = 2;
    "net.ipv6.conf.enp1s0.autoconf" = 1;
  };

  networking = with hosts; {
    hostName = router.hostName;
    nameservers = [ "127.0.0.1" "::1" ];

    vlans = {
      mgmt = {
        id = 1;
        interface = "enp2s0";
      };
      lab = {
        id = 2;
        interface = "enp3s0";
      };
      guest = {
        id = 3;
        interface = "enp4s0";
      };
      iot = {
        id = 4;
        interface = "enp4s0";
      };
    };

    interfaces = {
      enp1s0.useDHCP = true;
      enp2s0.useDHCP = false;
      enp3s0.useDHCP = false;
      enp4s0.useDHCP = false;
      mgmt.ipv4.addresses = [{
        address = "192.168.1.1";
        prefixLength = 24;
      }];
      lab.ipv4.addresses = [{
        address = "192.168.2.1";
        prefixLength = 24;
      }];
      guest.ipv4.addresses = [{
        address = "192.168.3.1";
        prefixLength = 24;
      }];
      iot.ipv4.addresses = [{
        address = "192.168.4.1";
        prefixLength = 24;
      }];
    };

  };

  environment.systemPackages = with pkgs; [
    ppp
    flashrom
    ethtool
    conntrack-tools
  ];

  services = {

    openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = "no";
    };

    sshguard.enable = true;

    tftpd.enable = true;

    # tailscale.enable = true;

    avahi = {
      interfaces = [ "guest" "iot" ];
      enable = true;
      reflector = true;
      # openFirewall = false;
    };

  };

  # systemd.services.tailscale-autoconnect = {
  #   description = "Automatic connection to Tailscale";
  #   # make sure tailscale is running before trying to connect to tailscale
  #   after = [ "network-pre.target" "tailscale.service" ];
  #   wants = [ "network-pre.target" "tailscale.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   # set this service as a oneshot job
  #   serviceConfig.Type = "oneshot";
  #   # have the job run this shell script
  #   script = with pkgs; ''
  #     sleep 2
  #     status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
  #     if [ $status = "Running" ]; then
  #       exit 0
  #     fi
  #     ${tailscale}/bin/tailscale up -authkey $(cat /var/lib/tailscale.key)
  #     rm /var/lib/tailscale.key
  #   '';
  # };

  programs.ssh.extraConfig = "IdentityFile /etc/ssh/ssh_host_ed25519_key";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

  nix = {
    distributedBuilds = true;
    buildMachines = [{
      hostName = "${hosts.hosts.server.hostName}.${hosts.domain}";
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }];
  };
}
