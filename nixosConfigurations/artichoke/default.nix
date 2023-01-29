{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.initrd.systemd.enable = true;

  hardware.clearfog-cn913x.enable = true;

  programs.flashrom.enable = true;
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "update-bios" ''
      ${config.programs.flashrom.package}/bin/flashrom \
        --programmer linux_mtd:dev=0 \
        --write ${pkgs.ubootCN9130_CF_Pro}/spi.img
    '')
  ];

  zramSwap.enable = true;
  system.stateVersion = "23.05";

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

  router.inventory.wan = config.systemd.network.links."10-wan".linkConfig.Name;

  custom = {
    server.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    disableZfs = true;
    wgWwwPeer.enable = true;
  };

  networking.hostName = "artichoke";
  networking.nftables.firewall.interfaces =
    let
      trusted = {
        allowedTCPPorts = [
          22 # ssh
          69 # tftp
          9153 # coredns
          9430 # corerad
          config.services.iperf3.port
          config.services.prometheus.exporters.blackbox.port
          config.services.prometheus.exporters.kea.port
          config.services.prometheus.exporters.node.port
          config.services.prometheus.exporters.wireguard.port
        ];
        allowedUDPPorts = [ config.services.iperf3.port ];
      };
    in
    {
      ${config.router.inventory.networks.mgmt.physical.interface} = trusted;
      ${config.router.inventory.networks.trusted.physical.interface} = trusted;
      ${config.router.inventory.networks.wg-trusted.physical.interface} = trusted;
      ${config.systemd.network.networks.www.name}.allowedTCPPorts = [
        19531 # systemd-journal-gatewayd
      ];
    };

  systemd.network.links = {
    "10-wan" = {
      matchConfig.OriginalName = "eth2";
      linkConfig.Name = "wan";
    };
    # 10Gbps link
    "10-data" = {
      matchConfig.OriginalName = "eth0";
      linkConfig.Name = "data";
    };
  };

  # Ensure the DSA master interface is bound to being up by it's slave
  # interfaces.
  systemd.network.networks.lan-master = {
    name = "eth1";
    linkConfig.RequiredForOnline = "no";
    networkConfig = {
      LinkLocalAddressing = "no";
      BindCarrier = map (i: "lan${toString i}") [ 1 2 3 4 5 ];
    };
  };

  services.ipwatch = {
    enable = true;
    extraArgs = [ "-4" ];
    filters = [ "!IsLoopback" "!IsPrivate" "IsGlobalUnicast" "IsValid" ];
    hookEnvironmentFile = config.sops.secrets.ipwatch_env.path;
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
}
