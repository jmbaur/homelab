{ ... }:

let
  caddyErrorHandling = ''
    handle_errors {
      respond "{err.status_code} {err.status_text}"
    }
  '';
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  custom.wgNetwork.nodes.pumpkin = {
    peer = true;
    initiate = true;
    endpointHost = "pumpkin.jmbaur.com";
  };

  custom.ddns = {
    enable = true;
    interface = config.router.wanInterface;
    domain = "jmbaur.com";
  };

  services.caddy = {
    enable = true;
    email = "jaredbaur@fastmail.com";
    virtualHosts = {
      "music.jmbaur.com".extraConfig = ''
        reverse_proxy http://pumpkin.internal:4533
        ${caddyErrorHandling}
      '';
      "jellyfin.jmbaur.com".extraConfig = ''
        reverse_proxy http://pumpkin.internal:8096
        ${caddyErrorHandling}
      '';
      "photos.jmbaur.com".extraConfig = ''
        reverse_proxy http://pumpkin.internal:2342
        ${caddyErrorHandling}
      '';
    };
  };
}
