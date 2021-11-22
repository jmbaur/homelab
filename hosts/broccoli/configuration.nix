{ config, pkgs, ... }:
with pkgs;
let
  domain = "home.arpa.";
  dynamic-hosts-file = "/var/lib/dhcp/hosts";
  update-hosts-script = writeShellScriptBin "update-hosts" ''
    ENTRY="$2 $3.${domain} $3"

    # Always remove old lease, failing silenty
    sed -i "/^''${ENTRY}$/d" ${dynamic-hosts-file}

    if [ "$1" == "commit" ] && [ "$2" != "" ] && [ "$3" != "" ]
    then
      sed -i "1i ''${ENTRY}" ${dynamic-hosts-file}
    fi
  '';
  dhcpd-event-config = (event: ''
    set clientip = binary-to-ascii(10, 8, ".", leased-address);
    set clientmac = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
    set clienthost = pick-first-value (option fqdn.hostname, option host-name, "");
    log(concat("${event}: IP: ", clientip, " Mac: ", clientmac, " Host: ", clienthost));
    execute("${update-hosts-script}/bin/update-hosts", "${event}", clientip, clienthost);
  '');
  steven-black-hosts = fetchFromGitHub {
    owner = "StevenBlack";
    repo = "hosts";
    rev = "56312e0607d9057689c93825c4a2f82d657eaabf";
    sha256 = "sha256-XrLwEdVlFg+7g9+JnMoezHimYSKUJsFFxtkcIZj8NAY=";
  };
in
{
  imports = [ ./options.nix ./secrets.nix ./hardware-configuration.nix ];

  boot = {
    loader = { grub = { enable = true; version = 2; device = "/dev/sda"; }; };
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

  security.sudo.enable = false;

  services = {
    avahi = { enable = true; reflector = true; ipv4 = true; ipv6 = true; };
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
    dhcpd4 = with config.custom.dhcpd4; {
      enable = true;
      interfaces = [ "eno2" ];
      extraConfig =
        ''
          ddns-update-style none;

          option domain-search "${domain}";
          option domain-name "${domain}";

          ${lib.concatMapStrings
            (ifi: with builtins.getAttr ifi interfaces; ''
              subnet ${subnet} netmask ${netmask} {
                range ${start} ${end};
                option routers ${router}; # TODO(jared): make this a list
                option broadcast-address ${broadcast};
                option subnet-mask ${netmask};
                option domain-name-servers ${dns};
              }
            '')
            (builtins.attrNames interfaces)}

          ${lib.concatMapStrings (event: ''
            on ${event} {
              ${dhcpd-event-config event}
            }
          '') ["commit" "release" "expiry"]}
        '';
    };
    coredns = with config.networking.interfaces; {
      enable = true;
      config =
        ''
          . {
            hosts ${steven-black-hosts}/hosts {
              fallthrough
            }
            forward . tls://1.1.1.1 tls://1.0.0.1 tls://2606:4700:4700::1111 tls://2606:4700:4700::1001 {
              tls_servername tls.cloudflare-dns.com
              health_check 5s
            }
            prometheus :9153
          }
          ${domain} {
            hosts ${dynamic-hosts-file} {
              ${lib.concatMapStrings (ifi: ''
                ${ifi.address} ${config.networking.hostName}.${domain}
              '') (eno2.ipv4.addresses ++ eno2.ipv6.addresses)}
            }
          }
        '';
    };
    corerad = with config.networking.interfaces; {
      enable = true;
      settings = {
        interfaces = [{
          verbose = true;
          name = "eno2";
          advertise = true;
          prefix = builtins.map
            (ifi: {
              prefix = "::/" + builtins.toString ifi.prefixLength;
            })
            eno2.ipv6.addresses;
          rdnss = [{
            servers = builtins.map (ifi: ifi.address) eno2.ipv6.addresses;
          }];
          dnssl = [{ domain_names = [ domain ]; }];
        }];
        debug = { address = ":9430"; prometheus = true; };
      };
    };
    iperf3.enable = true;
  };

  networking = {
    hostName = "broccoli";
    nameservers = [ "127.0.0.1" "::1" ];
    search = [ domain ];
    # The default gateway for IPv4 is populated by dhcpcd.
    defaultGateway6.interface = "hurricane";
    nat = {
      enable = true;
      externalInterface = "eno1";
      internalInterfaces = [ "eno2" ];
    };
    interfaces = {
      eno1.useDHCP = true;
      eno2.useDHCP = false;
      hurricane.useDHCP = false;
    };
    sits.hurricane = {
      dev = "eno1";
      ttl = 255;
    };
    dhcpcd = {
      enable = true;
      persistent = true;
      allowInterfaces = [ "eno1" ];
      extraConfig = ''
        # Disable ipv6 router solicitation
        noipv6rs
        # Override domain settings sent from ISP DHCPD
        static domain_name_servers=
        static domain_search=
        static domain_name=
      '';
    };
    firewall = {
      enable = true;
      package = pkgs.iptables-nftables-compat;
      trustedInterfaces = [ "eno2" ];
      interfaces = {
        eno2.allowedTCPPorts = [ 22 ];
      };
    };
  };

  system.activationScripts = {
    dynamic-hosts-file.text = ''
      if [ ! -f ${dynamic-hosts-file} ]
      then
        # Always ensures there is at minimum 1 line in the file so that the
        # script that updates this file can just do `sed -i "1i ..." ...`.
        echo > ${dynamic-hosts-file}
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
