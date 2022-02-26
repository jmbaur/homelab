{ config, lib, pkgs, ... }:
let
  mgmtIface = "enp5s0";
  mgmtAddress = "192.168.88.3";
  mgmtNetwork = "192.168.88.0";
  mgmtGateway = "192.168.88.1";
  mgmtNetmask = "255.255.255.0";
  mgmtPrefix = 24;
in
{
  imports = [ ./hardware-configuration.nix ];

  hardware.cpu.amd.updateMicrocode = true;

  nixpkgs.config.allowUnfree = true;

  custom.common.enable = true;
  custom.deploy.enable = true;
  custom.home.enable = true;
  custom.virtualisation.enable = true;
  custom.virtualisation.variant = "normal";

  systemd.services."serial-getty@ttyS2" = {
    enable = true;
    wantedBy = [ "getty.target" ]; # to start at boot
    serviceConfig.Restart = "always"; # restart when session is closed
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "riscv64-linux"
  ];
  boot.kernelParams = [
    "ip=${mgmtAddress}::${mgmtGateway}:${mgmtNetmask}:${config.networking.hostName}:${mgmtIface}::::"
    "console=ttyS2,115200"
    "console=tty1"
  ];
  boot.kernel.sysctl = {
    "net.ipv6.conf.enp5s0.accept_ra" = lib.mkForce 0;
    "net.ipv6.conf.enp5s0.autoconf" = lib.mkForce 0;
    "net.ipv6.conf.enp5s0.use_tempaddr" = lib.mkForce 0;
    "net.ipv6.conf.enp3s0.accept_ra" = lib.mkForce 0;
    "net.ipv6.conf.enp3s0.autoconf" = lib.mkForce 0;
    "net.ipv6.conf.enp3s0.use_tempaddr" = lib.mkForce 0;
    "net.ipv6.conf.pubwan.accept_ra" = lib.mkForce 0;
    "net.ipv6.conf.pubwan.autoconf" = lib.mkForce 0;
    "net.ipv6.conf.pubwan.use_tempaddr" = lib.mkForce 0;
    "net.ipv6.conf.publan.accept_ra" = lib.mkForce 0;
    "net.ipv6.conf.publan.autoconf" = lib.mkForce 0;
    "net.ipv6.conf.publan.use_tempaddr" = lib.mkForce 0;
  };
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

  time.timeZone = "America/Los_Angeles";

  networking = {
    hostName = "kale";
    domain = "home.arpa";
    firewall = {
      enable = true;
      interfaces.${mgmtIface} = {
        allowedTCPPorts = config.services.openssh.ports ++ [
          config.services.prometheus.exporters.node.port
        ];
      };
    };
    nameservers = lib.singleton mgmtGateway;
    defaultGateway.address = mgmtGateway;
    defaultGateway.interface = mgmtIface;
    interfaces.${mgmtIface} = {
      useDHCP = false;
      ipv4.addresses = [{ address = mgmtAddress; prefixLength = mgmtPrefix; }];
    };
    interfaces.enp3s0.ipv4.addresses = lib.mkForce [ ];
    vlans.pubwan = { id = 10; interface = "enp3s0"; };
    vlans.publan = { id = 20; interface = "enp3s0"; };
    interfaces.pubwan.ipv4.addresses = lib.mkForce [ ];
    interfaces.publan.ipv4.addresses = lib.mkForce [ ];
  };

  services.openssh = {
    permitRootLogin = "yes";
    openFirewall = false;
  };

  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = false;
    enabledCollectors = [ "systemd" ];
  };

  containers.www = {
    macvlans = [ "pubwan" ];
    autoStart = true;
    ephemeral = true;
    bindMounts."/home/jared" = {
      hostPath = "/fast/containers/www/git";
      isReadOnly = false;
    };
    bindMounts."/var/cache/cgit" = {
      hostPath = "/fast/containers/www/cgit";
      isReadOnly = false;
    };
    bindMounts."/var/lib/nginx".hostPath = "/fast/containers/www/nginx";
    bindMounts."/var/lib/nix-serve".hostPath = "/fast/containers/www/nix-serve";
    bindMounts."/etc/ssh/ssh_host_rsa_key".hostPath = "/etc/ssh/ssh_host_rsa_key";
    bindMounts."/etc/ssh/ssh_host_ed25519_key".hostPath = "/etc/ssh/ssh_host_ed25519_key";
    config = { config, ... }: {
      imports = [ ../../containers/www.nix ];
      # services.prometheus.exporters.nginx = {
      #   enable = true;
      #   openFirewall = false;
      # };
      services.nginx.statusPage = true;
      networking = {
        useHostResolvConf = false;
        defaultGateway.address = "192.168.10.1";
        defaultGateway.interface = "mv-pubwan";
        nameservers = lib.singleton "192.168.10.1";
        domain = "home.arpa";
        interfaces.mv-pubwan.ipv4.addresses = [{
          address = "192.168.10.11";
          prefixLength = 24;
        }];
        interfaces.mv-pubwan.ipv6.addresses = [{
          address = "2001:470:f001:10::11";
          prefixLength = 64;
        }];
      };
    };
  };

  containers.grafana = {
    macvlans = [ "publan" ];
    autoStart = true;
    ephemeral = true;
    bindMounts."/var/lib/grafana" = {
      hostPath = "/fast/containers/grafana";
      isReadOnly = false;
    };
    config = { config, ... }: {
      imports = [ ../../containers/grafana.nix ];
      networking = {
        useHostResolvConf = false;
        interfaces.mv-publan.useDHCP = true;
      };
    };
  };

  containers.builder = {
    macvlans = [ "publan" ];
    autoStart = true;
    ephemeral = true;
    config = {
      imports = [ ../../containers/builder.nix ];
      networking = {
        useHostResolvConf = false;
        interfaces.mv-publan.useDHCP = true;
      };
    };
  };

  containers.plex = {
    macvlans = [ "publan" ];
    autoStart = true;
    ephemeral = true;
    bindMounts."/media".hostPath = "/big/media";
    bindMounts."/var/lib/plex" = {
      hostPath = "/fast/containers/plex";
      isReadOnly = false;
    };
    config = {
      imports = [ ../../containers/plex.nix ];
      networking = {
        useHostResolvConf = false;
        interfaces.mv-publan.useDHCP = true;
      };
    };
  };

  containers.torrent = {
    macvlans = [ "publan" ];
    autoStart = true;
    ephemeral = true;
    bindMounts."/var/lib/jackett" = {
      hostPath = "/fast/containers/torrent/jackett";
      isReadOnly = false;
    };
    bindMounts."/var/lib/sonarr" = {
      hostPath = "/fast/containers/torrent/sonarr";
      isReadOnly = false;
    };
    bindMounts."/var/lib/lidarr" = {
      hostPath = "/fast/containers/torrent/lidarr";
      isReadOnly = false;
    };
    bindMounts."/var/lib/radarr" = {
      hostPath = "/fast/containers/torrent/radarr";
      isReadOnly = false;
    };
    bindMounts."/media" = {
      hostPath = "/big/media";
      isReadOnly = false;
    };
    config = {
      networking = {
        useHostResolvConf = false;
        defaultGateway.address = "192.168.20.1";
        defaultGateway.interface = "mv-publan";
        nameservers = lib.singleton "192.168.20.1";
        domain = "home.arpa";
        interfaces.mv-publan.ipv4.addresses = [{
          address = "192.168.20.29";
          prefixLength = 24;
        }];
        interfaces.mv-publan.ipv6.addresses = [{
          address = "2001:470:f001:20::29";
          prefixLength = 64;
        }];
      };
      imports = [ ../../containers/torrent.nix ];
    };
  };

  containers.minecraft = {
    macvlans = [ "publan" ];
    autoStart = true;
    ephemeral = true;
    bindMounts."/var/lib/minecraft" = {
      hostPath = "/fast/containers/minecraft";
      isReadOnly = false;
    };
    config = {
      imports = [ ../../containers/minecraft.nix ];
      networking = {
        useHostResolvConf = false;
        interfaces.mv-publan.useDHCP = true;
      };
    };
  };

  users.users.jared = {
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../../data/jmbaur-ssh-keys.nix);
    extraGroups = [ "wheel" "libvirtd" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
