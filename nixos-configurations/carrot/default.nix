{ config, pkgs, inputs, ... }: {
  imports = [
    (import ../disko-single-disk-encrypted.nix "/dev/nvme0n1")
    ./minimal.nix
  ];

  system.build.installer = (pkgs.nixos ({
    imports = [
      ({ modulesPath, ... }: { imports = [ "${modulesPath}/profiles/all-hardware.nix" ]; })
      inputs.self.nixosModules.default
      ./minimal.nix
    ];
    custom.tinyboot-installer.enable = true;
  })).config.system.build.diskImage;

  sops.defaultSopsFile = ./secrets.yaml;

  hardware.bluetooth.enable = true;

  zramSwap.enable = true;

  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];

  boot.initrd.systemd.enable = true;

  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    networks.ether = {
      matchConfig.Type = "ether";
      DHCP = "yes";
      dhcpV4Config.ClientIdentifier = "mac";
    };
  };

  custom = {
    server.enable = true;
    remoteBoot.enable = false;
    deployee = {
      enable = true;
      sshTarget = "root@carrot.home.arpa";
      authorizedKeyFiles = [ pkgs.jmbaur-ssh-keys ];
    };
  };

  custom.wg-mesh = {
    enable = true;
    peers.squash.dnsName = "squash.jmbaur.com";
  };

  custom.builder.build = {
    "tinyboot-qemu" = {
      flakeUri = "github:jmbaur/tinyboot#coreboot.qemu-${pkgs.stdenv.hostPlatform.qemuArch}.config.build.firmware";
      frequency = "*-*-* 20:00:00";
    };
    "carrot-firmware" = {
      flakeUri = "github:jmbaur/homelab#nixosConfigurations.carrot.config.system.build.firmware";
      frequency = "*-*-* 12:00:00";
    };
    "beetroot-system-closure" = {
      flakeUri = "github:jmbaur/homelab#nixosConfigurations.beetroot.config.system.build.toplevel";
      frequency = "*-*-* 22:00:00";
    };
    "squash-system-closure" = {
      flakeUri = "github:jmbaur/homelab#nixosConfigurations.squash.config.system.build.toplevel";
      frequency = "*-*-* 00:00:00";
    };
    "pea-sd-image" = {
      flakeUri = "github:jmbaur/homelab#nixosConfigurations.pea.config.system.build.sdImage";
      frequency = "*-*-* 01:00:00";
    };
    "potato-system-closure" = {
      flakeUri = "github:jmbaur/homelab#nixosConfigurations.potato.config.system.build.toplevel";
      frequency = "*-*-* 02:00:00";
    };
    "cn9130-kernel" = {
      flakeUri = "github:jmbaur/homelab#nixosConfigurations.installer_sd_image_cn9130_clearfog.config.system.build.kernel";
      frequency = "*-*-* 04:00:00";
    };
    "cn9130-firmware" = {
      flakeUri = "github:jmbaur/homelab#nixosConfigurations.installer_sd_image_cn9130_clearfog.config.system.build.firmware";
      frequency = "*-*-* 05:00:00";
    };
  };

  services.harmonia = {
    enable = true;
    signKeyPath = "/var/lib/secrets/harmonia.secret";
    settings = { };
  };

  networking.firewall.allowedTCPPorts = [ 443 80 ];

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedZstdSettings = true;
    recommendedGzipSettings = true;
    virtualHosts."carrot.home.arpa" = {
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
        zstd_types application/x-nix-archive;
      '';
    };
  };

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
    enable = false;
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

  services.tailscale.enable = true;
}
