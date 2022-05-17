{
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [
        "ethtool"
        "network_route"
        "systemd"
      ];
    };
    wireguard.enable = true;
  };
}
