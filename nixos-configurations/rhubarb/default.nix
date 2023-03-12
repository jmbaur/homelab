{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64.nix" ];

  services.tailscale.enable = true;
  environment.systemPackages = [ pkgs.tailscale ];
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up -authkey $(cat /var/lib/tskey)
    '';
  };
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    allowedTCPPorts = [ 22 ];
  };

  custom = {
    server.enable = true;
    disableZfs = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
    wg-mesh = {
      enable = true;
      peers.artichoke.extraConfig = {
        Endpoint = "vpn.jmbaur.com:51820";
        PersistentKeepalive = 25;
      };
    };
  };

  zramSwap.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.initrd.systemd.enable = true;

  networking.hostName = "rhubarb";
  networking.useDHCP = false;
  services.resolved = {
    enable = true;
    # The RPI does not have an RTC, so DNSSEC without an accurate time does not
    # work, which means NTP servers cannot be queried.
    dnssec = "false";
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.wg0 = { mode = "0640"; group = config.users.groups.systemd-network.name; };
  };

  systemd.network = {
    enable = true;
    networks.wired = {
      name = "en*";
      DHCP = "yes";
      dhcpV4Config.ClientIdentifier = "mac";
    };
  };

  system.stateVersion = "23.05";
}
