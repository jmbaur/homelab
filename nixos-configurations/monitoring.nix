{
  config,
  lib,
  pkgs,
  ...
}:

let
  nodeExporter = config.services.prometheus.exporters.node;

  # Served by prometheus at /consoles/<name>.html
  consoles = pkgs.linkFarm "prometheus-consoles" [
    {
      name = "index.html";
      path = ./monitoring.html;
    }
  ];
in
{
  # Each host scrapes only its own node exporter.
  # TODO(jared): Add centralized monitoring for all hosts.
  config = lib.mkIf config.custom.server.enable {
    # Let every homelab host view the monitoring site.
    custom.yggdrasil.allKnownPeers.allowedTCPPorts = [ config.services.prometheus.port ];

    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "logind"
        "systemd"
      ];
    };

    services.prometheus = {
      enable = true;
      listenAddress = "[::]";
      retentionTime = "30d";
      globalConfig.scrape_interval = "15s";
      extraFlags = [
        "--storage.tsdb.retention.size=1GB"
        "--web.console.templates=${consoles}"
        "--web.console.libraries=${pkgs.emptyDirectory}"
      ];
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString nodeExporter.port}" ];
              labels.instance = config.networking.hostName;
            }
          ];
        }
      ];
    };
  };
}
