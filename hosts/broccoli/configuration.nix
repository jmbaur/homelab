{ config, pkgs, ... }: {
  imports = [
    ./atftpd.nix
    ./coredns.nix
    ./hardware-configuration.nix
    ./lan.nix
    ./monitoring.nix
    ./nftables.nix
    ./options.nix
    ./wan.nix
    ./wireguard.nix
  ];

  custom.common.enable = true;
  custom.deployee.enable = true;
  custom.jared.enable = true;

  documentation.enable = false;

  boot.kernelPackages = pkgs.linuxPackages_5_17;
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

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
    secrets.beetroot = { };
    secrets.pixel = { };
    secrets.ipwatch.restartUnits = [ "ipwatch.service" ];
  };

  environment.systemPackages = with pkgs; [ ethtool nmap ];

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
  };

  systemd.services.ipwatch.serviceConfig.EnvironmentFile = config.sops.secrets.ipwatch.path;
  services.ipwatch = {
    enable = true;
    interfaces = [ config.systemd.network.networks.wan.matchConfig.Name ];
    hookScript = "${pkgs.writeShellScriptBin "ipwatch-exe" ''
      echo Updating Cloudflare DNS with new IP
      ${pkgs.curl}/bin/curl --silent \
        --request PUT \
        --header "Content-Type: application/json" \
        --header "Authorization: Bearer ''${CF_DNS_API_TOKEN}" \
        --data '{"type":"A","name":"vpn.jmbaur.com","content":"'"''${ADDR}"'","proxied":false}' \
        "https://api.cloudflare.com/client/v4/zones/''${CF_ZONE_ID}/dns_records/''${VPN_CF_RECORD_ID}" | ${pkgs.jq}/bin/jq

      echo Updating hurricane electric tunnelbroker with new IP
      ${pkgs.curl}/bin/curl --silent \
        --data "hostname=''${HE_TUNNEL_ID}" \
        --user "''${HE_USERNAME}:''${HE_PASSWORD}" \
        https://ipv4.tunnelbroker.net/nic/update
    ''}/bin/ipwatch-exe";
  };

  services.avahi = {
    enable = false;
    openFirewall = false;
    extraConfig = ''
      [server]
      deny-interfaces=${config.systemd.network.networks.wan.matchConfig.Name}
    '';
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
