{ config, pkgs, ... }: {
  imports = [
    ../../modules/hardware/cn913x.nix
    ./dhcp.nix
    ./dns.nix
    ./firewall.nix
    ./hardware.nix
    ./lan.nix
    ./monitoring.nix
    ./ntp.nix
    ./wan.nix
    ./wireguard.nix
  ];

  zramSwap.enable = true;
  system.stateVersion = "22.11";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets =
      let
        # wgSecret is a sops secret that has file permissions that can be
        # consumed by systemd-networkd. Reference:
        # https://www.freedesktop.org/software/systemd/man/systemd.netdev.html#PrivateKeyFile=
        wgSecret = { mode = "0640"; group = config.users.groups.systemd-network.name; };
      in
      {
        ipwatch_env = { };
        "wg/iot/artichoke" = wgSecret;
        "wg/iot/phone" = { };
        "wg/www/artichoke" = wgSecret;
        "wg/trusted/artichoke" = wgSecret;
        "wg/trusted/beetroot" = { };
      };
  };

  custom = {
    minimal.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    disableZfs = true;
    wgWwwPeer.enable = true;
  };

  services.ipwatch = {
    enable = true;
    package = pkgs.pkgsCross.aarch64-multiplatform.ipwatch;
    extraArgs = [ "-4" ];
    filters = [ "!IsLoopback" "!IsPrivate" "IsGlobalUnicast" "IsValid" ];
    environmentFile = config.sops.secrets.ipwatch_env.path;
    interfaces = [ config.systemd.network.networks.wan.name ];
    hooks =
      let
        updateCloudflare = pkgs.writeShellScript "update-cloudflare" ''
          ${pkgs.curl}/bin/curl \
            --silent \
            --show-error \
            --request PUT \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer ''${CF_DNS_API_TOKEN}" \
            --data '{"type":"A","name":"vpn.jmbaur.com","content":"'"''${ADDR}"'","proxied":false}' \
            "https://api.cloudflare.com/client/v4/zones/''${CF_ZONE_ID}/dns_records/''${VPN_CF_RECORD_ID}" | ${pkgs.jq}/bin/jq
        '';
        updateHE = pkgs.writeShellScript "update-he" ''
          ${pkgs.curl}/bin/curl \
            --silent \
            --show-error \
            --data "hostname=''${HE_TUNNEL_ID}" \
            --user "''${HE_USERNAME}:''${HE_PASSWORD}" \
            https://ipv4.tunnelbroker.net/nic/update
        '';
      in
      [ "internal:echo" "executable:${updateCloudflare}" "executable:${updateHE}" ];
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

  services.atftpd.enable = true;
  systemd.tmpfiles.rules = [
    "L+ ${config.services.atftpd.root}/netboot.xyz.efi 644 root root - ${pkgs.netbootxyz-efi}"
  ];

  networking = {
    hostName = "artichoke";
    useNetworkd = true;
  };
  systemd.network.enable = true;
}
