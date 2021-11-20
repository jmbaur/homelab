{ config, pkgs, ... }:
with pkgs;
let
  domain = "home.arpa.";
  dynamic-hosts-file = "/var/run/hosts";
  update-hosts-script = writeShellScriptBin "update-hosts" ''
    case $1 in
      "commit")
        if [ "$2" != "" ] && [ "$3" != "" ] && ! grep -q "^$2 $3.${domain}$" ${dynamic-hosts-file}
        then
          echo "$2 $3.${domain}" >> ${dynamic-hosts-file}
        fi
      ;;
      "release")
        sed -i "/^$2 $3.${domain}$/d" ${dynamic-hosts-file}
      ;;
      "expiry")
        sed -i "/^$2 $3.${domain}$/d" ${dynamic-hosts-file}
      ;;
    esac
  '';
in
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

  environment.systemPackages = with pkgs; [
    conntrack-tools
    dig
    ethtool
    htop
    powertop
    ppp
    tcpdump
    tmux
    vim
  ];

  programs.mtr.enable = true;

  services = {
    avahi = {
      enable = true;
      reflector = true;
      ipv4 = true;
      ipv6 = true;
    };
    openssh = {
      enable = true;
      passwordAuthentication = false;
      openFirewall = false;
      listenAddresses = [
        {
          addr = "192.168.1.1";
          port = 22;
        }
      ];
    };
    dhcpd4 = {
      enable = true;
      interfaces = [ "eno2" ];
      machines = [
        { ethernetAddress = "94:a6:7e:69:99:3e"; hostName = "GS308EP"; ipAddress = "192.168.1.13"; }
        { ethernetAddress = "9c:c9:eb:9d:d5:9f"; hostName = "NETGEAR9DD59F"; ipAddress = "192.168.1.14"; }
        { ethernetAddress = "5c:80:b6:92:eb:27"; hostName = "asparagus"; ipAddress = "192.168.1.15"; }
        { ethernetAddress = "b0:e4:d5:cb:ac:33"; hostName = "Chromecast"; ipAddress = "192.168.1.16"; }
        { ethernetAddress = "dc:a6:32:20:50:f2"; hostName = "rhubarb"; ipAddress = "192.168.1.17"; }
      ];
      extraConfig = ''
        ddns-update-style none;

        option domain-search "${domain}";
        option domain-name "${domain}";

        default-lease-time 86400;
        max-lease-time 86400;

        subnet 192.168.1.0 netmask 255.255.255.0 {
          range 192.168.1.100 192.168.1.200;
          option routers 192.168.1.1;
          option broadcast-address 192.168.1.255;
          option subnet-mask 255.255.255.0;
          option domain-name-servers 192.168.1.1;
        }

        on commit {
          set clientip = binary-to-ascii(10, 8, ".", leased-address);
          set clientmac = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
          set clienthost = pick-first-value (option fqdn.hostname, option host-name, "");
          log(concat("Commit: IP: ", clientip, " Mac: ", clientmac, " Host: ", clienthost));
          execute("${update-hosts-script}/bin/update-hosts", "commit", clientip, clienthost);
        }
        on release {
          set clientip = binary-to-ascii(10, 8, ".", leased-address);
          set clientmac = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
          set clienthost = pick-first-value (option fqdn.hostname, option host-name, "");
          log(concat("Release: IP: ", clientip, " Mac: ", clientmac, " Host: ", clienthost));
          execute("${update-hosts-script}/bin/update-hosts", "release", clientip, clienthost);
        }
        on expiry {
          set clientip = binary-to-ascii(10, 8, ".", leased-address);
          set clientmac = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
          set clienthost = pick-first-value (option fqdn.hostname, option host-name, "");
          log(concat("Expiry: IP: ", clientip, " Mac: ", clientmac, " Host: ", clienthost));
          execute("${update-hosts-script}/bin/update-hosts", "expiry", clientip, clienthost);
        }
      '';
    };
    coredns = {
      enable = true;
      config =
        ''
          . {
            forward . tls://1.1.1.1 tls://1.0.0.1 tls://2606:4700:4700::1111 tls://2606:4700:4700::1001 {
              tls_servername tls.cloudflare-dns.com
              health_check 5s
            }
            prometheus localhost:9153
          }
          ${domain} {
            hosts ${dynamic-hosts-file} {
              192.168.1.1 ${config.networking.hostName}.${domain}
            }
          }
        '';
    };
    corerad = {
      enable = true;
      settings = {
        interfaces = [
          {
            name = "eno2";
            advertise = true;
            managed = false;
            prefix = [{ prefix = "::/64"; }];
          }
        ];
        debug = {
          address = "localhost:9430";
          prometheus = true;
        };
      };
    };
  };

  networking = {
    hostName = "broccoli";
    nameservers = [ "127.0.0.1" "::1" ];
    search = [ domain ];
    # The default gateway for IPv4 is populated by dhcpcd.
    defaultGateway6 = {
      address = "2001:470:c:10c9::1";
      interface = "hurricane";
    };
    nat = {
      enable = true;
      externalInterface = "eno1";
      internalInterfaces = [ "eno2" ];
    };
    interfaces = {
      eno1.useDHCP = true;
      eno2 = {
        useDHCP = false;
        ipv4.addresses = [{ address = "192.168.1.1"; prefixLength = 24; }];
        ipv6.addresses = [{ address = "2001:470:f457:1000::1"; prefixLength = 64; }];
      };
      hurricane = {
        useDHCP = false;
        ipv6.addresses = [{ address = "2001:470:c:10c9::2"; prefixLength = 64; }];
      };
    };
    sits.hurricane = {
      dev = "eno1";
      remote = "66.220.18.42";
      ttl = 255;
    };
    dhcpcd = {
      enable = true;
      persistent = true;
      allowInterfaces = [ "eno1" ];
      extraConfig = ''
      '';
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

  system.activationScripts = {
    dynamic-hosts-file.text = ''
      if [ ! -f ${dynamic-hosts-file} ]
      then
        touch ${dynamic-hosts-file}
        chown dhcpd:nogroup ${dynamic-hosts-file}
      fi
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
