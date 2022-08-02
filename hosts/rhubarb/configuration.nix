{ config, lib, pkgs, ... }: {
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

  zramSwap.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_5_18;

  networking = {
    hostName = "rhubarb";
    useDHCP = false;
    useNetworkd = true;
    firewall.allowedTCPPorts = [ config.services.prometheus.port ];
  };
  services.resolved = {
    enable = true;
    # The RPI does not have an RTC, so DNSSEC without an accurate time does not
    # work, which means NTP servers cannot be queried.
    dnssec = "false";
  };

  services.cage = {
    enable = true;
    user = config.users.users.browser.name;
    program = "${pkgs.firefox-wayland}/bin/firefox --kiosk --private-window http://localhost:9090/consoles/index.html";
    extraArguments = [ "-d" ];
  };

  systemd.network = {
    enable = true;
    networks.wired = {
      name = "eth*";
      DHCP = "yes";
      dhcpV4Config.ClientIdentifier = "mac";
    };
  };

  users.users = {
    browser.isNormalUser = true;
    jared = {
      isNormalUser = true;
      extraGroups = [ "dialout" "wheel" ];
      packages = with pkgs; [ picocom tmux wol ];
      openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
    };
  };

  services.prometheus = {
    enable = true;
    exporters = {
      node = {
        enable = true;
        openFirewall = false;
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
      {
        job_name = "coredns";
        static_configs = [{ targets = [ "artichoke.mgmt.home.arpa:9153" ]; }];
      }
      {
        job_name = "vpn";
        static_configs = [{ targets = [ "artichoke.mgmt.home.arpa:${toString config.services.prometheus.exporters.wireguard.port}" ]; }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    users = {
      allowSignUp = false;
      allowOrgCreate = false;
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
      dashboards = map
        (d: with d; {
          inherit name;
          options.path = pkgs.fetchurl {
            inherit url sha256;
            name = "${name}-dashboard.json";
          };
        })
        (lib.importJSON ./dashboards.json);
    };
  };

  services.caddy = {
    enable = false;
    email = "jaredbaur@fastmail.com";
    virtualHosts = { };
  };

  system.stateVersion = "22.11";
}
