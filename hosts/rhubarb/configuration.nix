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
    extraFlags = [
      "--web.console.templates=${pkgs.homelab-console-templates}/consoles"
      "--web.console.libraries=${pkgs.homelab-console-templates}/console_libraries"
    ];
    exporters = {
      node = {
        enable = true;
        # openFirewall = true;
        enabledCollectors = [ "systemd" ];
      };
    };
    # TODO(jared): configure these:
    #   - "artichoke.mgmt.home.arpa:${toString config.services.prometheus.exporters.wireguard.port}"
    #   - "artichoke.mgmt.home.arpa:9153" # coredns
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "rhubarb.mgmt.home.arpa:${toString config.services.prometheus.port}" ];
        }];
      }
      {
        job_name = "node";
        static_configs = [{
          # TODO(jared): Use DNS-SD
          targets = [
            "artichoke.mgmt.home.arpa:${toString config.services.prometheus.exporters.node.port}"
            "rhubarb.mgmt.home.arpa:${toString config.services.prometheus.exporters.node.port}"
          ];
        }];
      }
    ];
  };

  system.stateVersion = "22.11";
}
