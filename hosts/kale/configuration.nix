{ config, lib, pkgs, ... }:
let
  dataIface = "enp1s0";
  mgmtIface = "enp35s0";
in
{
  imports = [ ./hardware-configuration.nix ];

  hardware.cpu.amd.updateMicrocode = true;

  nixpkgs.config.allowUnfree = true;

  custom.common.enable = true;
  custom.deploy.enable = true;
  custom.jared.enable = true;

  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "getty.target" ]; # to start at boot
    serviceConfig.Restart = "always"; # restart when session is closed
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_5_17;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  time.timeZone = "America/Los_Angeles";

  networking = {
    hostName = "kale";
    useDHCP = false;
    firewall = {
      enable = true;
      interfaces.${mgmtIface} = {
        allowedTCPPorts = config.services.openssh.ports ++ [
          config.services.prometheus.exporters.node.port
        ];
      };
    };
    interfaces.${mgmtIface}.useDHCP = true;
    vlans.pubwan = { id = 10; interface = dataIface; };
    vlans.publan = { id = 20; interface = dataIface; };
    vlans.trusted = { id = 30; interface = dataIface; };
    bridges.br-pubwan.interfaces = [ "pubwan" ];
    bridges.br-publan.interfaces = [ "publan" ];
    bridges.br-trusted.interfaces = [ "trusted" ];
  };

  users.users.jared.hashedPassword = "$6$COYoxPUJ2GXytmXc$7XkhoFMy3KIatPD73I/zeDmseXH0l8pQ.kYrFvHphdqf.jitZ/PR2lhcSn67EsF4FwHIu85itj2ASEi3kGR/b/";

  services.fwupd.enable = true;
  services.iperf3.enable = true;

  programs.mosh.enable = true;
  services.openssh = {
    permitRootLogin = "yes";
    openFirewall = false;
  };

  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = false;
    enabledCollectors = [ "systemd" ];
  };

  # Ensure that bind mount directories exist on the host.
  systemd.tmpfiles.rules = [
    "d /fast/containers/www/git 700 - - -"
    "d /fast/containers/www/acme 700 - - -"
    "d /fast/containers/www/ssh 700 - - -"
    "d /fast/containers/www/fail2ban 700 - - -"
    "d /fast/containers/media/plex 700 - - -"
    "d /fast/containers/media/sops-nix 700 - - -"
    "d /big/containers/media/content 700 - - -"
  ];

  containers.www = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostBridge = "br-pubwan";
    localAddress = "192.168.10.10/24";
    localAddress6 = "2001:470:f001:a::a/64";
    extraVeths.eth1 = {
      hostBridge = "br-publan";
      localAddress = "192.168.20.10/24";
      localAddress6 = "fd82:f21d:118d:14::a/64";
    };
    bindMounts."/var/lib/fail2ban" = {
      hostPath = "/fast/containers/www/fail2ban";
      isReadOnly = false;
    };
    bindMounts."/srv/git" = {
      hostPath = "/fast/containers/www/git";
      isReadOnly = false;
    };
    bindMounts."/var/lib/acme" = {
      hostPath = "/fast/containers/www/acme";
      isReadOnly = false;
    };
    bindMounts."/etc/ssh" = {
      hostPath = "/fast/containers/www/ssh";
      isReadOnly = false;
    };
  };

  containers.media = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostBridge = "br-publan";
    localAddress = "192.168.20.20/24";
    localAddress6 = "fd82:f21d:118d:14::14/64";
    bindMounts."/media" = {
      hostPath = "/big/containers/media/content";
      isReadOnly = false;
    };
    bindMounts."/var/lib/plex" = {
      hostPath = "/fast/containers/media/plex";
      isReadOnly = false;
    };
    bindMounts."/var/lib/sops-nix" = {
      hostPath = "/fast/containers/media/sops-nix";
      isReadOnly = false;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
