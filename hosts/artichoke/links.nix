{
  systemd.network = {
    links = {
      "10-wan" = {
        matchConfig.OriginalName = "eth2";
        linkConfig.Name = "wan";
      };
      # 10Gbps link
      "10-data" = {
        matchConfig.OriginalName = "eth0";
        linkConfig.Name = "data";
      };
    };
  };
}
