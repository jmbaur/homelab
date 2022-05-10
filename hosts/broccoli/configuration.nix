{ config, pkgs, ... }: {
  imports = [
    ./atftpd.nix
    ./coredns.nix
    ./corerad.nix
    ./dhcpd4.nix
    ./dhcpd6.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./nftables.nix
    ./options.nix
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
    secrets.wg-trusted = {
      mode = "0640";
      owner = config.users.users.root.name;
      group = config.users.groups.systemd-network.name;
    };
    secrets.wg-iot = {
      mode = "0640";
      owner = config.users.users.root.name;
      group = config.users.groups.systemd-network.name;
    };
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

  systemd.services.ipwatch.serviceConfig.EnvironmentFiles = [
    "/run/secrets/he_tunnelbroker"
    "/run/secrets/cloudflare"
  ];
  systemd.services.ipwatch.serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];

  services.ipwatch = {
    enable = true;
    iface = config.systemd.network.networks.wan.matchConfig.Name;
    exe = "${pkgs.writeShellScriptBin "ipwatch-exe" ''
      echo Updating hurricane electric tunnelbroker with new IP
      ${pkgs.curl}/bin/curl \
        --data "hostname=''${HE_TUNNEL_ID}" \
        --user "''${HE_USERNAME}:''${HE_PASSWORD}" \
        https://ipv4.tunnelbroker.net/nic/update

      echo Updating Cloudflare DNS with new IP
      ${pkgs.curl}/bin/curl \
        --request PUT \
        --header "Content-Type: application/json" \
        --header "Authorization: Bearer ''${CF_DNS_API_TOKEN}" \
        --data '{"type":"A","name":"jmbaur.com","content":"'"''${ADDR}"'","proxied":false}' \
        "https://api.cloudflare.com/client/v4/zones/''${CF_ZONE_ID}/dns_records/''${CF_RECORD_ID}" | ${pkgs.jq}/bin/jq
    ''}/bin/ipwatch-exe";
  };

  services.avahi = {
    enable = true;
    reflector = true;
    interfaces = with config.systemd.network.networks; [
      trusted.matchConfig.Name
      iot.matchConfig.Name
    ];
    ipv4 = true;
    ipv6 = true;
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    openFirewall = false;
    allowSFTP = false;
  };

  services.iperf3 = {
    enable = true;
    openFirewall = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
