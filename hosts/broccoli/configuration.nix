{ config, pkgs, ... }: {
  imports = [
    ./atftpd.nix
    ./coredns.nix
    ./corerad.nix
    ./dhcpcd.nix
    ./dhcpd4.nix
    ./dhcpd6.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./nftables.nix
  ];

  custom.common.enable = true;
  custom.deploy.enable = true;

  documentation.enable = false;

  boot.kernelPackages = pkgs.linuxPackages_5_17;
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.wg-trusted = { };
    secrets.wg-iot = { };
    secrets.cloudflare = { };
    secrets.he_tunnelbroker = { };
  };

  environment.systemPackages = with pkgs; [
    conntrack-tools
    dig
    ethtool
    ipmitool
    powertop
    ppp
    tcpdump
  ];

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$P6479NO62cb9PQAw$dEKrzW6W6TdEd6Kc8h.QrzhhzUJyyLBeJ.lVXGRn68xQOjcFe8xsJMnzf3PahUz0Msn44cowN8cvkG/45RR3E/";
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
  };

  services.avahi = {
    enable = true;
    reflector = true;
    # interfaces = with config.networking.interfaces; [ trusted.name iot.name ];
    ipv4 = true;
    ipv6 = true;
  };
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    openFirewall = false;
    allowSFTP = false;
    # listenAddresses = (
    #   (builtins.map
    #     (ifi: { port = 22; addr = ifi.address; })
    #     mgmt.ipv4.addresses)
    #   ++
    #   (builtins.map
    #     (ifi: { port = 22; addr = "[" + ifi.address + "]"; })
    #     mgmt.ipv6.addresses)
    # );
  };
  services.iperf3.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
