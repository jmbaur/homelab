{ config, pkgs, ... }:
let
  wg = import ../../nixos-modules/mesh-network/inventory.nix;
in
{
  imports = [ ./hardware-configuration.nix ];

  fileSystems."/".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/home".options = [ "noatime" "discard=async" "compress=zstd" ];
  zramSwap.enable = true;

  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];
  boot.initrd.systemd.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  services.fwupd.enable = true;

  services.harmonia = {
    enable = true;
    signKeyPath = "/var/lib/secrets/harmonia.secret";
    settings = { };
  };

  networking.firewall.allowedTCPPorts = [ 443 80 ];

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedZstdSettings = false; # TODO(jared): doesn't build
    recommendedGzipSettings = false; # TODO(jared): doesn't build
    virtualHosts."okra.home.arpa" = {
      enableACME = false;
      forceSSL = false;
      locations."/".extraConfig = ''
        proxy_pass http://[::1]:5000;
        proxy_set_header Host $host;
        proxy_redirect http:// https://;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        gzip_types application/x-nix-archive;
      '';
    };
  };

  custom.builder.build = {
    "tinyboot-qemu" = {
      flakeUri = "github:jmbaur/tinyboot#coreboot.qemu-${pkgs.stdenv.hostPlatform.qemuArch}";
      frequency = "*-*-* 21:00:00";
    };
    "beetroot-firmware" = {
      flakeUri = "github:jmbaur/homelab#nixosConfigurations.beetroot.config.system.build.firmware";
      frequency = "*-*-* 23:00:00";
    };
    "squash-system-closure" = {
      flakeUri = "github:jmbaur/homelab#nixosConfigurations.squash.config.system.build.toplevel";
      frequency = "*-*-* 00:00:00";
    };
  };

  # sops.defaultSopsFile = ./secrets.yaml;
  # sops.secrets."wg0" = { mode = "0640"; group = config.users.groups.systemd-network.name; };

  networking.hostName = "okra";

  networking.useDHCP = false;
  networking.firewall.interfaces.eno1.allowedTCPPorts = [ 22 ];
  systemd.network.enable = true;

  systemd.network.networks.ethernet = {
    name = "en*";
    DHCP = "yes";
    dhcpV4Config.ClientIdentifier = "mac";
  };

  custom.wg-mesh = {
    enable = false;
    dns = true;
    peers.kale.extraConfig.Endpoint = "kale.home.arpa:51820";
    peers.squash.extraConfig.Endpoint = "squash.home.arpa:51820";
    peers.www.extraConfig = {
      Endpoint = "www.jmbaur.com:51820";
      PersistentKeepalive = 25;
    };
    firewall.ips."${wg.www.ip}".allowedTCPPorts = [ config.services.grafana.settings.server.http_port ];
  };

  custom.deployee = {
    enable = true;
    sshTarget = "root@okra.home.arpa";
    authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
  };
  custom.remoteBoot.enable = false;

  services.prometheus = {
    enable = false;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };
    };
    # TODO(jared): Use DNS-SD?
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [
            "artichoke.home.arpa:${toString config.services.prometheus.exporters.node.port}"
            "kale.home.arpa:${toString config.services.prometheus.exporters.node.port}"
          ];
        }];
      }
      {
        job_name = "prometheus";
        static_configs = [{ targets = [ "okra.home.arpa:${toString config.services.prometheus.port}" ]; }];
      }
      {
        job_name = "coredns";
        static_configs = [{ targets = [ "artichoke.home.arpa:9153" ]; }];
      }
      # {
      #   job_name = "blackbox";
      #   static_configs = [{ targets = [ "artichoke.home.arpa:${toString config.services.prometheus.exporters.blackbox.port}" ]; }];
      # }
      # {
      #   job_name = "icmpv4_connectivity";
      #   metrics_path = "/probe";
      #   params.module = [ "icmpv4_connectivity" ];
      #   static_configs = [{ targets = [ "he.net" "iana.org" ]; }];
      #   relabel_configs = [
      #     {
      #       source_labels = [ "__address__" ];
      #       target_label = "__param_target";
      #     }
      #     {
      #       source_labels = [ "__param_target" ];
      #       target_label = "instance";
      #     }
      #     {
      #       target_label = "__address__";
      #       replacement = "artichoke.home.arpa:${toString config.services.prometheus.exporters.blackbox.port}";
      #     }
      #   ];
      # }
      # {
      #   job_name = "icmpv6_connectivity";
      #   metrics_path = "/probe";
      #   params.module = [ "icmpv6_connectivity" ];
      #   static_configs = [{ targets = [ "he.net" "iana.org" ]; }];
      #   relabel_configs = [
      #     {
      #       source_labels = [ "__address__" ];
      #       target_label = "__param_target";
      #     }
      #     {
      #       source_labels = [ "__param_target" ];
      #       target_label = "instance";
      #     }
      #     {
      #       target_label = "__address__";
      #       replacement = "artichoke.home.arpa:${toString config.services.prometheus.exporters.blackbox.port}";
      #     }
      #   ];
      # }
    ];
  };

  services.journald.enableHttpGateway = true;

  services.grafana = {
    enable = true;
    settings = {
      auth.disable_login_form = true;
      "auth.anonymous".enabled = true;
      server = {
        domain = "mon.jmbaur.com";
        http_addr = "[::]";
      };
    };
    declarativePlugins = [ ];
    provision = {
      enable = true;
      datasources.settings.datasources = [{
        url = "http://localhost:${toString config.services.prometheus.port}";
        type = "prometheus";
        name = "prometheus";
        isDefault = true;
      }];
      dashboards.settings.providers = pkgs.grafana-dashboards.dashboards;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
