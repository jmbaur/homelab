{ config, pkgs, ... }: {
  imports = [
    ./dhcp.nix
    ./dns.nix
    ./firewall.nix
    ./lan.nix
    ./monitoring.nix
    ./options.nix
    ./ra.nix
    ./wan.nix
    ./wireguard.nix
  ];

  services.avahi = {
    enable = false;
    openFirewall = false;
    extraConfig = ''
      [server]
      deny-interfaces=${config.systemd.network.networks.wan.name}
    '';
  };

  services.journald.rateLimitBurst = 5000;

  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  services.iperf3 = {
    enable = true;
    openFirewall = false;
  };

  services.atftpd.enable = true;
  systemd.tmpfiles.rules = [
    "L+ ${config.services.atftpd.root}/netboot.xyz.efi 644 root root - ${pkgs.netbootxyz-efi}"
  ];

  services.ntp = {
    enable = true;
    # continue to serve time to the network in case internet access is lost
    extraConfig = ''
      tos orphan 15
    '';
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
  };
  systemd.network.enable = true;
}
