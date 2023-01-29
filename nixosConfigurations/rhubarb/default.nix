{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64.nix" ];

  custom = {
    server.enable = true;
    wgWwwPeer.enable = true;
    disableZfs = true;
    users.jared = {
      enable = true;
      passwordFile = config.sops.secrets.jared_password.path;
    };
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
  };

  zramSwap.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.initrd.systemd.enable = true;

  networking = {
    hostName = "rhubarb";
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      allowedTCPPorts = lib.mkForce [ ];
      interfaces = {
        www.allowedTCPPorts = lib.mkForce [
          config.services.grafana.settings.server.http_port
          19531 # systemd-journal-gatewayd
        ];
        end0.allowedTCPPorts = lib.mkForce [ 22 ];
      };
    };
  };
  services.resolved = {
    enable = true;
    # The RPI does not have an RTC, so DNSSEC without an accurate time does not
    # work, which means NTP servers cannot be queried.
    dnssec = "false";
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "wg/www/rhubarb" = {
        mode = "0640";
        group = config.users.groups.systemd-network.name;
      };
      jared_password.neededForUsers = true;
    };
  };

  systemd.network = {
    enable = true;
    networks.wired = {
      name = "end0";
      DHCP = "yes";
      dhcpV4Config.ClientIdentifier = "mac";
    };
  };

  environment.systemPackages = with pkgs; [ tmux picocom wol wireguard-tools ];

  services.prometheus = {
    enable = true;
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
            "artichoke.mgmt.home.arpa:${toString config.services.prometheus.exporters.node.port}"
            "kale.mgmt.home.arpa:${toString config.services.prometheus.exporters.node.port}"
            "rhubarb.mgmt.home.arpa:${toString config.services.prometheus.exporters.node.port}"
          ];
        }];
      }
      {
        job_name = "prometheus";
        static_configs = [{ targets = [ "rhubarb.mgmt.home.arpa:${toString config.services.prometheus.port}" ]; }];
      }
      {
        job_name = "coredns";
        static_configs = [{ targets = [ "artichoke.mgmt.home.arpa:9153" ]; }];
      }
      {
        job_name = "wireguard";
        static_configs = [{ targets = [ "artichoke.mgmt.home.arpa:${toString config.services.prometheus.exporters.wireguard.port}" ]; }];
      }
      {
        job_name = "kea";
        static_configs = [{ targets = [ "artichoke.mgmt.home.arpa:${toString config.services.prometheus.exporters.kea.port}" ]; }];
      }
      # {
      #   job_name = "blackbox";
      #   static_configs = [{ targets = [ "artichoke.mgmt.home.arpa:${toString config.services.prometheus.exporters.blackbox.port}" ]; }];
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
      #       replacement = "artichoke.mgmt.home.arpa:${toString config.services.prometheus.exporters.blackbox.port}";
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
      #       replacement = "artichoke.mgmt.home.arpa:${toString config.services.prometheus.exporters.blackbox.port}";
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

  system.stateVersion = "22.11";
}
