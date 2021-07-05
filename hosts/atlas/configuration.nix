# vim: set ts=2 sw=2 et
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let hosts = import ../hosts.nix;
in {
  imports = [
    ../../hardware-configuration.nix
    "${
      builtins.fetchGit {
        url = "https://github.com/NixOS/nixos-hardware.git";
        rev = "eb889532fef2cb73071436842ae2ca0ed2d011aa";
        ref = "master";
      }
    }/pcengines/apu"
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
  boot.kernelParams = [ "console=ttyS0,115200" "console=tty1" ];

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
    useDHCP = false;
    hostName = router.hostName;
    nameservers = [ "127.0.0.1" "::1" ];

    interfaces = {
      enp1s0.useDHCP = true;
      enp2s0 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.1.1";
          prefixLength = 24;
        }];
      };
      enp3s0.useDHCP = false;
      enp4s0.useDHCP = false;
    };

    dhcpcd = {
      enable = true;
      persistent = true;
      allowInterfaces = [ "enp1s0" ];
      extraConfig = ''
        noipv6rs
        interface enp1s0
          # TODO: look into this
          # ipv6rs
          # ia_na 0
          # ia_pd 1/::/64
          static domain_name_servers=127.0.0.1
          static domain_search=
          static domain_name=
      '';
    };

    nat = {
      enable = true;
      externalInterface = "enp1s0";
      internalIPs = [ "192.168.1.0/24" ];
      internalInterfaces = [ "enp2s0" ];
    };

    firewall = {
      enable = true;
      allowPing = true;
      interfaces = {
        enp1s0 = {
          allowedTCPPorts = [ ];
          allowedUDPPorts = [ config.services.tailscale.port ];
        };
      };
      trustedInterfaces = [ "enp2s0" "tailscale0" ];
    };

  };

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.jared = {
    isNormalUser = true;
    home = "/home/jared";
    description = "Jared Baur";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKU/J9T/6BwzloIiXP5wCkgkJbSl5B3z+c6Z/J3baa/u"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOTuM+py6p17ysZ3UXJHvwPZip58/+aGHKqbcKJlkbbA4wOOsWhlEhtunX139mNUoU9TtlzlcmlbAsAqP7Z05srOghO71Z48UqO5X7fnN3bP6k8/3FagYI1+JJs29Tp7bvKvjk+GT5AAiTW5cXaiWBkJ42wMJHi1CTI23V96U9TJA0suAkCYFie/cL0pWYljBCog3yrH8y629+p2IFNcIsHMcV0LvHmMQet5p4Cxg08+FX8nVWa+ZnpKNAEJ6M2Z84S4MKMiZ22MIqK4PeGEAesoeZ7PmDFEuE0STwiZ1IHkFoCj5Z/0hl2b0roQbzsoaklN2Sv8T+KfpD48TqEqCRozn6J5jqwq7dzKKr7HVUDSw+jjMzSSZKLr2CGoe790ljZTpHjftUyEO8OhuVh7jhbPEaPwikkqgvFBLdhL0uv3o4avs5vVxkpBpgjWCip1Z14iRjEWgxfOcPjS6LLs9IkgrUkTKvGAl+rhtqV6oZekYGjGxWN5UdMwfcmGijYhE="
    ];
  };

  environment.systemPackages = with pkgs; [
    tmux
    vim
    git
    curl
    htop
    nixfmt
    tcpdump
    ppp
    iperf3
    dnsutils
    iputils
    flashrom
    dmidecode
    ethtool
    conntrack-tools
  ];

  services = {

    openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = "no";
      openFirewall = false; # thanks, VPN!
    };

    sshguard.enable = true;

    tftpd.enable = true;

    tailscale.enable = false;

    coredns = {
      enable = true;
      config = with hosts; ''
        # Root zone
        . {
          forward . tls://8.8.8.8 tls://8.8.4.4 tls://2001:4860:4860::8888 tls://2001:4860:4860::8844 {
            tls_servername dns.google
            health_check 5s
          }
        }

        # Internal zone
        lan {
          hosts {
            ${router.ipAddress} ${router.hostName}.lan
            ${switch.ipAddress} ${switch.hostName}.lan
            ${ap.ipAddress} ${ap.hostName}.lan
            ${server.ipAddress} ${server.hostName}.lan
            ${laptop.ipAddress} ${laptop.hostName}.lan
          }
        }
      '';
    };

    dhcpd4 = {
      enable = true;
      interfaces = [ "enp2s0" ];
      machines = with hosts; [
        hosts.switch
        hosts.ap
        hosts.server
        hosts.laptop
      ];
      extraConfig = ''
        ddns-update-style none;

        default-lease-time 86400;
        max-lease-time 86400;

        subnet 192.168.1.0 netmask 255.255.255.0 {
          option routers 192.168.1.1;
          option broadcast-address 192.168.1.255;
          option subnet-mask 255.255.255.0;
          option domain-name-servers 192.168.1.1;
          range 192.168.1.100 192.168.1.200;

          allow booting;
          next-server 192.168.1.1;
          option bootfile-name "netboot.xyz.kpxe";

          option domain-search "lan";
          option domain-name "lan";
        }
      '';
    };

  };

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      sleep 2
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then
        exit 0
      fi
      ${tailscale}/bin/tailscale up -authkey $(cat /var/lib/tailscale.key)
      rm /var/lib/tailscale.key
    '';
  };

  programs.vim.defaultEditor = true;
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    keyMode = "vi";
    clock24 = true;
    baseIndex = 1;
    shortcut = "a";
    newSession = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}

