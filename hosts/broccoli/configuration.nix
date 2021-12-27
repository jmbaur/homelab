{ config, pkgs, ... }:
with pkgs;
let
  domain = "home.arpa.";
  dhcpd-hosts-file = "/var/lib/dhcp/hosts";
  update-hosts-script = writeShellScriptBin "update-hosts" ''
    HOST_ENTRY="$3.${domain} $3"
    FULL_ENTRY="$2 ''${HOST_ENTRY}"

    # Always remove old lease with same hostname
    sed -i "/^.*''${HOST_ENTRY}$/d" ${dhcpd-hosts-file}

    if [ "$1" == "commit" ] && [ "$2" != "" ] && [ "$3" != "" ]; then
      sed -i "1i ''${FULL_ENTRY}" ${dhcpd-hosts-file}
    fi
  '';
  dhcpd-event-config = (event: ''
    set clientip = binary-to-ascii(10, 8, ".", leased-address);
    set clientmac = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
    set clienthost = pick-first-value (option fqdn.hostname, option host-name, "");
    log(concat("${event}: IP: ", clientip, " Mac: ", clientmac, " Host: ", clienthost));
    execute("${update-hosts-script}/bin/update-hosts", "${event}", clientip, clienthost);
  '');
in
{
  imports = [ ./options.nix ./secrets.nix ./hardware-configuration.nix ];

  boot = {
    loader.grub = { enable = true; version = 2; device = "/dev/sda"; };
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
        deviceUri = "usb://Eastman%20Kodak%20Company/KODAK%20ESP%205200%20Series%20AiO?serial=G217374&interface=1"; # lpinfo -v
      }];
    };

  services = {
    printing = with config.networking.interfaces; {
      enable = true;
      browsing = true;
      defaultShared = true;
      logLevel = "debug";
      listenAddresses = lib.singleton "localhost:631" ++
        (builtins.map (ifi: ifi.address + ":631") eno2.ipv4.addresses) ++
        (builtins.map (ifi: "[" + ifi.address + "]:631") eno2.ipv6.addresses) ++
        (builtins.map (ifi: ifi.address + ":631") eno3.ipv4.addresses) ++
        (builtins.map (ifi: "[" + ifi.address + "]:631") eno3.ipv6.addresses) ++
        (builtins.map (ifi: ifi.address + ":631") eno4.ipv4.addresses) ++
        (builtins.map (ifi: "[" + ifi.address + "]:631") eno4.ipv6.addresses);
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
        ++
        (builtins.map
          (ifi: { port = 22; addr = ifi.address; })
          eno3.ipv4.addresses)
        ++
        (builtins.map
          (ifi: { port = 22; addr = "[" + ifi.address + "]"; })
          eno3.ipv6.addresses)
        ++
        (builtins.map
          (ifi: { port = 22; addr = ifi.address; })
          eno4.ipv4.addresses)
        ++
        (builtins.map
          (ifi: { port = 22; addr = "[" + ifi.address + "]"; })
          eno4.ipv6.addresses)

      );
    };
    dhcpd4 = with config.custom.dhcpd4; {
      enable = true;
      interfaces = [ "eno2" "eno3" "eno4" ];
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
        let
          steven-black-hosts = fetchFromGitHub {
            owner = "StevenBlack";
            repo = "hosts";
            rev = "56312e0607d9057689c93825c4a2f82d657eaabf";
            sha256 = "sha256-XrLwEdVlFg+7g9+JnMoezHimYSKUJsFFxtkcIZj8NAY=";
          };
          cloudflare-ipv4-1 = "1.1.1.1";
          cloudflare-ipv4-2 = "1.0.0.1";
          cloudflare-ipv6-1 = "2606:4700:4700::1111";
          cloudflare-ipv6-2 = "2606:4700:4700::1001";
        in
        ''
          . {
            hosts ${steven-black-hosts}/hosts {
              fallthrough
            }
            forward . tls://${cloudflare-ipv4-1} tls://${cloudflare-ipv4-2} tls://${cloudflare-ipv6-1} tls://${cloudflare-ipv6-2} {
              tls_servername tls.cloudflare-dns.com
              health_check 5s
            }
            prometheus :9153
          }
          ${domain} {
            hosts ${dhcpd-hosts-file} {
              ${lib.concatMapStrings (ifi: ''
                ${ifi.address} ${config.networking.hostName}.${domain}
              '') (eno2.ipv4.addresses ++ eno2.ipv6.addresses)}
              ${lib.concatMapStrings (ifi: ''
                ${ifi.address} ${config.networking.hostName}.${domain}
              '') (eno3.ipv4.addresses ++ eno3.ipv6.addresses)}
              ${lib.concatMapStrings (ifi: ''
                ${ifi.address} ${config.networking.hostName}.${domain}
              '') (eno4.ipv4.addresses ++ eno4.ipv6.addresses)}
            }
          }
        '';
    };
    corerad = with config.networking.interfaces; {
      enable = true;
      settings = {
        interfaces = builtins.map
          (ifi:
            {
              verbose = true;
              name = ifi.name;
              advertise = true;
              prefix = builtins.map
                (addr: {
                  prefix = "::/" + builtins.toString addr.prefixLength;
                })
                ifi.ipv6.addresses;
              rdnss = [{
                servers = builtins.map (addr: addr.address) ifi.ipv6.addresses;
              }];
              dnssl = [{ domain_names = [ domain ]; }];
            }
          ) [ eno2 eno3 eno4 ]
        ;
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
      internalInterfaces = [ "eno2" "eno3" "eno4" ];
    };
    interfaces = {
      eno1.useDHCP = true;
      eno2.useDHCP = false;
      eno3.useDHCP = false;
      eno4.useDHCP = false;
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
      trustedInterfaces = [ "eno2" "eno3" "eno4" ];
      interfaces = {
        eno2.allowedTCPPorts = [ 22 ];
        eno3.allowedTCPPorts = [ 22 ];
        eno4.allowedTCPPorts = [ 22 ];
      };
    };
  };

  systemd.services.update-tunnelbroker-ip = {
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "/run/keys/tunnelbroker";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 3;
    };
    wantedBy = [ "dhcpcd.service" ];
    path = with pkgs; [ bash curl ];
    script = ''
      curl --verbose \
        --data "hostname=''${TUNNEL_ID}" \
        --user "''${USERNAME}:''${PASSWORD}" \
        https://ipv4.tunnelbroker.net/nic/update
    '';
  };

  system.activationScripts.dhcpd-hosts-file.text = ''
    if [ ! -f ${dhcpd-hosts-file} ]; then
      # Always ensures there is at minimum 1 line in the file so that the
      # script that updates this file can just do `sed -i "1i ..." ...`.
      echo > ${dhcpd-hosts-file}
      chown dhcpd:nogroup ${dhcpd-hosts-file}
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
