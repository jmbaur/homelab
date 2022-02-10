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
      interfaces.trusted = {
        allowedTCPPorts = [ 80 ];
      };
    };
    nameservers = lib.singleton mgmtGateway;
    defaultGateway.address = mgmtGateway;
    defaultGateway.interface = mgmtIface;
  };

  systemd.network =
    let
      unconfiguredMasterNetworkConfig = {
        LinkLocalAddressing = "no";
        LLDP = "no";
        EmitLLDP = "no";
        IPv6AcceptRA = "no";
        IPv6SendRA = "no";
      };
    in
    {
      enable = true;
      netdevs.trusted = {
        netdevConfig = {
          Name = "trusted";
          Kind = "vlan";
        };
        vlanConfig.Id = 10;
      };
      netdevs.git = {
        netdevConfig.Name = "git";
        netdevConfig.Kind = "macvlan";
        macvlanConfig.Mode = "bridge";
      };
      netdevs.ubuntu = {
        netdevConfig.Name = "ubuntu";
        netdevConfig.Kind = "macvtap";
        extraConfig = ''
          [MACVTAP]
          Mode=bridge
        '';
      };
      networks.enp5s0 = {
        matchConfig.Name = "enp5s0";
        networkConfig = {
          Address = mgmtAddress + "/" + toString mgmtPrefix;
          Gateway = mgmtGateway;
        };
      };
      networks.enp3s0 = {
        matchConfig.Name = "enp3s0";
        vlan = [ "trusted" ];
        networkConfig = unconfiguredMasterNetworkConfig;
      };
      networks.trusted = {
        matchConfig.Name = "trusted";
        networkConfig = unconfiguredMasterNetworkConfig;
        macvlan = [ "git" ];
        extraConfig = ''
          MACVTAP=ubuntu
        '';
      };
    };

  containers.git = {
    interfaces = lib.singleton "git";
    autoStart = true;
    ephemeral = true;
    bindMounts."/srv/git" = {
      hostPath = "/fast/git";
      isReadOnly = false;
    };
    bindMounts."/etc/ssh/ssh_host_rsa_key".hostPath = "/etc/ssh/ssh_host_rsa_key";
    bindMounts."/etc/ssh/ssh_host_ed25519_key".hostPath = "/etc/ssh/ssh_host_ed25519_key";
    forwardPorts = [{ containerPort = 80; }];
    config = import ../../containers/git.nix;
  };

  users.users.jared = {
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../../data/jmbaur-ssh-keys.nix);
    extraGroups = lib.singleton "libvirtd";
  };

  services.openssh.permitRootLogin = "yes";
  users.users.root.openssh.authorizedKeys.keys =
    (import ../../data/asparagus-ssh-keys.nix)
    ++
    (import ../../data/beetroot-ssh-keys.nix);

  # services.iperf3.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
