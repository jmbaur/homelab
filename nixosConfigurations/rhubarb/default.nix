{ config, lib, pkgs, ... }: {
  custom = {
    wgWwwPeer.enable = true;
    disableZfs = true;
    common.enable = true;
    users.jared.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [
        ../../data/deployer-ssh-keys.txt
        pkgs.jmbaur-github-ssh-keys
      ];
    };
  };

  zramSwap.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_5_19;

  networking = {
    hostName = "rhubarb";
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      allowedTCPPorts = lib.mkForce [ ];
      interfaces = {
        wg-public.allowedTCPPorts = lib.mkForce [
          3000 # grafana
          19531 # systemd-journal-gatewayd
        ];
        eth0.allowedTCPPorts = lib.mkForce [ 22 ];
      };
    };
  };
  services.resolved = {
    enable = true;
    # The RPI does not have an RTC, so DNSSEC without an accurate time does not
    # work, which means NTP servers cannot be queried.
    dnssec = "false";
  };

  age.secrets.wg-public-rhubarb = {
    mode = "0640";
    group = config.users.groups.systemd-network.name;
    file = ../../secrets/wg-public-rhubarb.age;
  };

  systemd.network = {
    enable = true;
    networks.wired = {
      name = "eth*";
      DHCP = "yes";
      dhcpV4Config.ClientIdentifier = "mac";
    };
  };

  environment.systemPackages = with pkgs; [ picocom wol wireguard-tools ];

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
    addr = "0.0.0.0";
    port = 3000;
    auth = {
      disableLoginForm = true;
      anonymous.enable = true;
    };
    declarativePlugins = [ ];
    provision = {
      enable = true;
      datasources = [{
        url = "http://localhost:${toString config.services.prometheus.port}";
        type = "prometheus";
        name = "prometheus";
        isDefault = true;
      }];
      dashboards = pkgs.grafana-dashboards.dashboards;
    };
  };

  system.stateVersion = "22.11";
}
