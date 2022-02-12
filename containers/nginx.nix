{ config, lib, pkgs, ... }:
let
  cgitrc = pkgs.writeText "cgitrc" ''
    about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
    source-filter=${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    snapshots=tar.gz zip
    cache-size=1000
    remove-suffix=1
    scan-path=${config.services.gitDaemon.basePath}
  '';
in
{
  # TODO(jared): don't open 80
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    enable = true;
    virtualHosts."_" =
      let
        index = pkgs.writeText "index.html" ''
          <h1>These aren’t the droids you’re looking for.</h1>
        '';
      in
      {
        default = true;
        locations."/" = {
          extraConfig = ''
            index ${index};
          '';
        };
      };
    virtualHosts."git.jmbaur.com" = {
      locations."~* ^.+(cgit.(css|png)|favicon.ico|robots.txt)" = {
        extraConfig = ''
          root ${pkgs.cgit}/cgit;
          expires 30d;
        '';
      };
      locations."/" = {
        extraConfig = ''
          include ${pkgs.nginx}/conf/fastcgi_params;
          fastcgi_param CGIT_CONFIG ${cgitrc};
          fastcgi_param SCRIPT_FILENAME ${pkgs.cgit}/cgit/cgit.cgi;
          fastcgi_split_path_info ^(/?)(.+)$;
          fastcgi_param PATH_INFO $fastcgi_path_info;
          fastcgi_param QUERY_STRING $args;
          fastcgi_param HTTP_HOST $server_name;
          fastcgi_pass 192.168.10.21:5678;
        '';
      };
    };
  };
}
