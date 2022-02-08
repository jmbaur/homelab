{ config, lib, pkgs, ... }:
let
  mgmt-iface = "enp5s0";
  mgmt-address = "192.168.88.3";
  mgmt-network = "192.168.88.0";
  mgmt-gateway = "192.168.88.1";
  mgmt-netmask = "255.255.255.0";
  mgmt-prefix = 24;
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
    "ip=${mgmt-address}::${mgmt-gateway}:${mgmt-netmask}:${config.networking.hostName}:${mgmt-iface}::::"
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
    nameservers = lib.singleton "192.168.88.1";
    defaultGateway.address = "192.168.88.1";
    defaultGateway.interface = "enp5s0";
    interfaces.${mgmt-iface} = {
      useDHCP = false;
      ipv4.addresses = [{ address = mgmt-address; prefixLength = mgmt-prefix; }];
      ipv4.routes = [{ address = mgmt-network; prefixLength = mgmt-prefix; via = mgmt-gateway; }];
    };
    vlans.trusted = { id = 10; interface = "enp3s0"; };
    vlans.iot = { id = 20; interface = "enp3s0"; };
    vlans.guest = { id = 30; interface = "enp3s0"; };
  };

  containers.git = {
    macvlans = [ "trusted" ];
    autoStart = true;
    bindMounts."/srv/git".hostPath = "/fast/git";
    forwardPorts = [{ containerPort = 80; }];
    config = import ../../containers/git.nix;
  };

  users.users.jared = {
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../../data/jmbaur-ssh-keys.nix);
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
