{ config, pkgs, inventory, ... }: {
  imports = [
    ./atftpd.nix
    ./dhcpv6.nix
    ./dns.nix
    ./hardware-configuration.nix
    ./lan.nix
    ./monitoring.nix
    ./nftables.nix
    ./options.nix
    ./wan.nix
    ./wireguard.nix
  ];

  custom = {
    common.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [
        (import ../../data/jmbaur-ssh-keys.nix)
        ../../data/deployer-ssh-keys.txt
      ];
    };
  };

  documentation.enable = false;
  fonts.fontconfig.enable = false;

  boot.kernelPackages = pkgs.linuxPackages_5_18;
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  age = {
    secrets = {
      wg-trusted = {
        mode = "0640";
        group = config.users.groups.systemd-network.name;
        file = ../../secrets/wg-trusted.age;
      };
      wg-iot = {
        mode = "0640";
        group = config.users.groups.systemd-network.name;
        file = ../../secrets/wg-iot.age;
      };
      beetroot.file = ../../secrets/beetroot.age;
      pixel.file = ../../secrets/pixel.age;
      ipwatch.file = ../../secrets/ipwatch.age;
    };
  };

  environment.systemPackages = with pkgs; [ ethtool nmap ];

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
  };

  systemd.services.ipwatch.serviceConfig.EnvironmentFile = config.age.secrets.ipwatch.path;
  services.ipwatch = {
    enable = true;
    interfaces = [ config.systemd.network.networks.wan.name ];
    scripts =
      let
        updateCloudflare = pkgs.writeShellScriptBin "update-cloudflare" ''
          ${pkgs.curl}/bin/curl \
            --silent \
            --show-error \
            --request PUT \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer ''${CF_DNS_API_TOKEN}" \
            --data '{"type":"A","name":"vpn.${inventory.tld}","content":"'"''${ADDR}"'","proxied":false}' \
            "https://api.cloudflare.com/client/v4/zones/''${CF_ZONE_ID}/dns_records/''${VPN_CF_RECORD_ID}" | ${pkgs.jq}/bin/jq
        '';
        updateHE = pkgs.writeShellScriptBin "update-he" ''
          ${pkgs.curl}/bin/curl \
            --silent \
            --show-error \
            --data "hostname=''${HE_TUNNEL_ID}" \
            --user "''${HE_USERNAME}:''${HE_PASSWORD}" \
            https://ipv4.tunnelbroker.net/nic/update
        '';
      in
      [
        "${updateCloudflare}/bin/update-cloudflare"
        "${updateHE}/bin/update-he"
      ];
  };

  services.avahi = {
    enable = false;
    openFirewall = false;
    extraConfig = ''
      [server]
      deny-interfaces=${config.systemd.network.networks.wan.name}
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
