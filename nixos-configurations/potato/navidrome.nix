{ config, ... }:
{
  custom.wgNetwork.nodes.celery.allowedTCPPorts = [ config.services.navidrome.settings.Port ];

  services.navidrome = {
    enable = true;
    settings = {
      Address = "[::]";
      Port = 4533;
      DefaultTheme = "Auto";
    };
  };
}
