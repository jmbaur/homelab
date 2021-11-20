{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot = {
    loader = {
      grub = {
        enable = true;
        version = 2;
        device = "/dev/sda";
      };
    };
    kernelParams = [ "console=ttyS0,115200" "console=tty1" ];
    kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = { font = "Lat2-Terminus16"; keyMap = "us"; };

  users.mutableUsers = false;

  environment.systemPackages = with pkgs; [ conntrack-tools ppp ethtool vim ];

  programs.mtr.enable = true;

  services = {
    avahi = {
      enable = true;
      reflector = true;
    };
    openssh = {
      enable = true;
      passwordAuthentication = false;
      openFirewall = false;
      listenAddresses = [
        {
          addr = "192.168.100.1";
          port = 22;
        }
      ];
    };
    dhcpd4 = {
      enable = true;
      interfaces = [ "eno2" ];
      extraConfig = ''
        ddns-update-style none;

        default-lease-time 86400;
        max-lease-time 86400;

        subnet 192.168.100.0 netmask 255.255.255.0 {
          range 192.168.100.100 192.168.100.200;
          option routers 192.168.100.1;
          option broadcast-address 192.168.100.255;
          option subnet-mask 255.255.255.0;
          option domain-name-servers 192.168.100.1;
          option domain-search "home.arpa";
          option domain-name "home.arpa";
        }
      '';
    };
    coredns = {
      enable = true;
      config = ''
        . {
           forward . tls://1.1.1.1 tls://1.0.0.1 tls://2606:4700:4700::1111 tls://2606:4700:4700::1001 {
             tls_servername tls.cloudflare-dns.com
             health_check 5s
           }
           prometheus :9153
         }
      '';
    };
  };

  networking = {
    hostName = "broccoli";
    nat = {
      enable = true;
      externalInterface = "eno1";
      internalInterfaces = [ "eno2" ];
    };
    interfaces = {
      eno1.useDHCP = true;
      eno2 = {
        useDHCP = false;
        ipv4.addresses = [{ address = "192.168.100.1"; prefixLength = 24; }];
      };
    };
    dhcpcd = {
      enable = true;
      persistent = true;
      allowInterfaces = [ "eno1" ];
    };
    firewall = {
      enable = true;
      package = pkgs.iptables-nftables-compat;
      trustedInterfaces = [ "eno2" "enp1s0f0" "enp1s0f1" ];
      interfaces = {
        eno2.allowedTCPPorts = [ 22 ];
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
