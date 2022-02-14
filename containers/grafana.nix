{ config, lib, pkgs, ... }:
let
  staticScrape = (job_name: targets: {
    inherit job_name;
    static_configs = [{ inherit targets; }];
  });
in
{
  networking.firewall.allowedTCPPorts = [ config.services.grafana.port ];
  services.prometheus = {
    enable = true;
    scrapeConfigs = [ (staticScrape "kale" [ "kale.home.arpa:9100" ]) ];
  };
  services.grafana = {
    enable = true;
    addr = "";
    domain = config.networking.hostName;
    declarativePlugins = [ ];
    provision = {
      enable = true;
      datasources = [
        {
          type = "prometheus";
          name = "prometheus";
          isDefault = true;
          url = "http://localhost:${toString config.services.prometheus.port}";
        }
      ];
    };
  };
}
