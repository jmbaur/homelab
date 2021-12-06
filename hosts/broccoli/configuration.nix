{ config, pkgs, ... }:
with pkgs;
let
  domain = "home.arpa.";
  dynamic-hosts-file = "/var/lib/dhcp/hosts";
  update-hosts-script = writeShellScriptBin "update-hosts" ''
    HOST_ENTRY="$3.${domain} $3"
    FULL_ENTRY="$2 ''${HOST_ENTRY}"

    # Always remove old lease with same hostname
    sed -i "/^.*''${HOST_ENTRY}$/d" ${dynamic-hosts-file}

    if [ "$1" == "commit" ] && [ "$2" != "" ] && [ "$3" != "" ]; then
      sed -i "1i ''${FULL_ENTRY}" ${dynamic-hosts-file}
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
    kernelModules = [ "ipmi_devintf" "ipmi_si" ];
    kernelParams = [ "console=ttyS0,115200" "console=tty1" ];
    kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };
  };

  users = {
    mutableUsers = false;
    users.mgmt-user = {
      isNormalUser = true;
      passwordFile = "/run/keys/mgmt-user";
      openssh.authorizedKeys.keys =
        builtins.filter
          (str: builtins.stringLength str != 0)
          (lib.splitString "\n" (builtins.readFile ../../lib/ssh_keys.txt));
    };
  };

  environment.systemPackages = with pkgs; [
    conntrack-tools
    dig
    ethtool
    htop
    ipmitool
    powertop
    ppp
    tcpdump
    tmux
    vim
  ];

  hardware.printers = let kodak = "KodakESP5200+0822"; in
    {
      ensureDefaultPrinter = kodak;
      ensurePrinters = [{
        name = kodak;
        location = "Office";
        model = "drv:///KodakESP_16.drv/Kodak_ESP_52xx_Series.ppd"; # lpinfo -m
        deviceUri = "dnssd://KodakESP5200+0822._pdl-datastream._tcp.local/"; # lpinfo -v
      }];
    };

  services = {
    printing = with config.networking.interfaces; {
      enable = true;
      browsing = true;
      defaultShared = true;
      logLevel = "debug";
      listenAddresses =
        (builtins.map (ifi: ifi.address + ":631") eno2.ipv4.addresses) ++
        (builtins.map (ifi: "[" + ifi.address + "]:631") eno2.ipv6.addresses);
      allowFrom = [ "all" ];
      drivers = [
        (stdenv.mkDerivation rec {
          name = "c2esp";
          version = "27";
          nativeBuildInputs = with pkgs; [ cups cups-filters jbigkit zlib ];
          src = fetchurl {
            url = "mirror://sourceforge/cupsdriverkodak/${name}-${version}.tar.gz";
            sha256 = "sha256-8JX5y7U5zUi3XOxv4vhEugy4hmzl5DGK1MpboCJDltQ=";
          };
          # prevent ppdc not finding <font.defs>
          CUPS_DATADIR = "${pkgs.cups}/share/cups";
          preConfigure = ''
            configureFlags="--with-cupsfilterdir=$out/lib/cups/filter"
          '';
          NIX_CFLAGS_COMPILE = [ "-include stdio.h" ];
          installPhase = ''
            mkdir -p $out/lib/cups/filter $out/lib/cups/ppd $out/share/cups/drv

            substituteInPlace src/KodakESP_16.drv \
              --replace "/usr" "$out"
            substituteInPlace src/KodakESP_16.drv \
              --replace "/usr" "$out"

            cp ppd/*.ppd $out/lib/cups/ppd/
            cp src/*.drv $out/share/cups/drv/
            cp src/c2esp $out/lib/cups/filter/c2esp
            cp src/c2espC $out/lib/cups/filter/c2espC
            cp src/command2esp $out/lib/cups/filter/command2esp
          '';
        })
      ];
    };
    avahi = {
      enable = true;
      reflector = true;
      ipv4 = true;
      ipv6 = true;
      publish = {
        enable = true;
        userServices = true;
      };
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
    dhcpd4 = with config.custom.dhcpd4; {
      enable = true;
      interfaces = [ "eno2" ];
      extraConfig = ''
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

        ${lib.concatMapStrings
        (event: ''
          on ${event} {
            ${dhcpd-event-config event}
          }
        '')
        ["commit" "release" "expiry"]}
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
      trustedInterfaces = [ "eno2" ];
      interfaces = {
        eno2.allowedTCPPorts = [ 22 ];
      };
    };
  };

  system.activationScripts.dynamic-hosts-file.text = ''
    if [ ! -f ${dynamic-hosts-file} ]; then
      # Always ensures there is at minimum 1 line in the file so that the
      # script that updates this file can just do `sed -i "1i ..." ...`.
      echo > ${dynamic-hosts-file}
      chown dhcpd:nogroup ${dynamic-hosts-file}
    fi
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
