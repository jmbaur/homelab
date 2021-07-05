# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let hosts = import ../hosts.nix;
in {
  imports = [ ../../hardware-configuration.nix ../../common.nix ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = with hosts; hosts.server.hostName;

  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.eno2.useDHCP = true;

  programs.mosh.enable = true;
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };
  services.tailscale.enable = true;

  services.prometheus = {
    enable = true;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };
    };
    scrapeConfigs = with hosts; [
      {
        job_name = hosts.server.hostName;
        static_configs = with config.services.prometheus.exporters; [{
          targets = [ "127.0.0.1:${toString node.port}" ];
        }];
      }
      {
        job_name = router.hostName;
        static_configs = [{ targets = [ "${router.ipAddress}:9153" ]; }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    addr = "";
  };

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      sleep 2
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then
        exit 0
      fi
      ${tailscale}/bin/tailscale up -authkey $(cat /var/lib/tailscale.key)
      rm /var/lib/tailscale.key
    '';
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      signal-cli-rest-api = {
        image = "bbernhard/signal-cli-rest-api:0.41";
        environment = { USE_NATIVE = "0"; };
        volumes = [
          "${config.users.users.jared.home}/.local/share/signal-cli:/home/.local/share/signal-cli"
        ];
        ports = [ "8080:8080" ];
      };
    };
  };

  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBoevyW2csdOqpNeqxXr4X/Sg9yF5nIGAVqjS8S0oBkM root@atlas"
  ];
}
