{ config, pkgs, inventory, ... }: {
  imports = [
    ./atftpd.nix
    ./dhcpv6.nix
    ./dns.nix
    ./lan.nix
    ./links.nix
    ./monitoring.nix
    ./nftables.nix
    ./ntp.nix
    ./wan.nix
    ./wireguard.nix
  ];

  custom.disableZfs = true;
  hardware.cn913x.enable = true;
  zramSwap.enable = true;
  system.stateVersion = "22.11";

  # Minimize total build size
  documentation.enable = false;
  fonts.fontconfig.enable = false;

  age.secrets =
    let
      mkWgSecret = file: {
        mode = "0640";
        group = config.users.groups.systemd-network.name; inherit file;
      };
    in
    {
      ipwatch.file = ../../secrets/ipwatch.age;
      wg-iot-artichoke = mkWgSecret ../../secrets/wg-iot-artichoke.age;
      wg-iot-phone.file = ../../secrets/wg-iot-phone.age;
      wg-public-artichoke = mkWgSecret ../../secrets/wg-public-artichoke.age;
      wg-trusted-artichoke = mkWgSecret ../../secrets/wg-trusted-artichoke.age;
      wg-trusted-beetroot.file = ../../secrets/wg-trusted-beetroot.age;
      wg-trusted-carrot.file = ../../secrets/wg-trusted-carrot.age;
    };

  custom = {
    minimal.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [
        pkgs.jmbaur-github-ssh-keys
        ../../data/deployer-ssh-keys.txt
      ];
    };
  };

  services.ipwatch = {
    enable = true;
    environmentFile = config.age.secrets.ipwatch.path;
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

  services.journald.rateLimitBurst = 5000;

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

  networking = {
    hostName = "artichoke";
    useNetworkd = true;
  };
  systemd.network.enable = true;
}
