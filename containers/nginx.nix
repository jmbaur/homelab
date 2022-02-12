{ config, lib, pkgs, ... }:
let
  cgitrc = pkgs.writeText "cgitrc" ''
    about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
    source-filter=${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    snapshots=tar.gz zip
    # cache-size=1000
    # cache-root=/var/cache/cgit
    remove-suffix=1
    scan-path=/srv/git
  '';
  vhostSsl = {
    forceSSL = true;
    sslCertificate = "/var/lib/nginx/jmbaur.com.cert";
    sslCertificateKey = "/var/lib/nginx/jmbaur.com.key";
  };
  vhostLogging = {
    extraConfig = ''
      error_log syslog:server=unix:/dev/log;
      access_log syslog:server=unix:/dev/log combined_host;
    '';
  };
  mkVhost = settings: settings // vhostSsl // vhostLogging;
in
{
  # TODO(jared): don't open 80
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    enable = true;
    virtualHosts."_" =
      let
        index = pkgs.runCommandNoCC "index" { } ''
          mkdir -p $out
          cat > $out/index.html << EOF
          <h1>These aren't the droids you're looking for.</h1>
          EOF
        '';
      in
      mkVhost {
        default = true;
        locations."/" = {
          root = index;
          index = "index.html";
        };
      };
    virtualHosts."git.jmbaur.com" = mkVhost {
      locations."~* ^.+(cgit.(css|png)|favicon.ico|robots.txt)" = {
        root = "${pkgs.cgit}/cgit";
        extraConfig = ''
          expires 30d;
        '';
      };
      locations."/" = {
        fastcgiParams = {
          CGIT_CONFIG = "${cgitrc}";
          SCRIPT_FILENAME = "${pkgs.cgit}/cgit/cgit.cgi";
          PATH_INFO = "$fastcgi_path_info";
          QUERY_STRING = "$args";
          HTTP_HOST = "$server_name";
        };
        extraConfig = ''
          include ${pkgs.nginx}/conf/fastcgi_params;
          fastcgi_split_path_info ^(/?)(.+)$;
          fastcgi_pass 192.168.10.21:5678;
        '';
      };
    };
  };
}
