{ config, pkgs, inventory, ... }: {
  imports = [
    ./atftpd.nix
    ./dhcpv6.nix
    ./dns.nix
    ./lan.nix
    ./links.nix
    ./monitoring.nix
    ./nftables.nix
    ./options.nix
    ./wan.nix
    ./wireguard.nix
  ];

  hardware.cn913x.enable = true;
  zramSwap.enable = true;
  system.stateVersion = "22.11";

  # Minimize total build size
  documentation.enable = false;
  fonts.fontconfig.enable = false;

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
      wg-work = {
        mode = "0640";
        group = config.users.groups.systemd-network.name;
        file = ../../secrets/wg-work.age;
      };
      beetroot.file = ../../secrets/beetroot.age;
      pixel.file = ../../secrets/pixel.age;
      ipwatch.file = ../../secrets/ipwatch.age;
    };
  };

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

  services.openntpd = {
    enable = true;
    extraConfig = ''
      listen on *
    '';
  };

  networking = {
    hostName = "artichoke";
    useNetworkd = true;
  };
  systemd.network.enable = true;

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
  };
}
