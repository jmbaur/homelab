{ config, lib, pkgs, ... }:
let
  cgitrc = pkgs.writeText "cgitrc" ''
    source-filter=''${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    about-filter=''${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
    cache-size=1000
    scan-path=${config.services.gitDaemon.basePath}
  '';
in
{
  services.gitDaemon = {
    enable = true;
    exportAll = true;
    basePath = "/srv/git";
  };
  services.lighttpd = {
    enable = true;
    enableModules = [ "mod_cgi" "mod_rewrite" "mod_setenv" ];
    extraConfig = ''
      #$SERVER["socket"] == ":443" {
      $SERVER["socket"] == ":80" {
          #ssl.engine                    = "enable"
          #ssl.pemfile                   = "/etc/lighttpd/ssl/git.example.com.pem"

          server.name          = "git.example.com"
          server.document-root = "${pkgs.cgit}/cgit/"

          index-file.names     = ( "cgit.cgi" )
          cgi.assign           = ( "cgit.cgi" => "" )
          mimetype.assign      = ( ".css" => "text/css" )
          url.rewrite-once     = (
              "^/cgit/cgit.css"   => "/cgit.css",
              "^/cgit/cgit.png"   => "/cgit.png",
              "^/([^?/]+/[^?]*)?(?:\?(.*))?$"   => "/cgit.cgi?url=$1&$2",
          )
          setenv.add-environment = (
              "CGIT_CONFIG" => "${cgitrc}"
          )
      }
    '';
  };
  systemd.services.lighttpd.preStart = ''
    mkdir -p /var/cache/cgit
    chown lighttpd:lighttpd /var/cache/cgit
  '';
  networking.firewall.allowedTCPPorts = [ 80 ];
  networking.interfaces.mv-trusted.useDHCP = true;
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  users.users.git = {
    home = config.services.gitDaemon.basePath;
    createHome = true;
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../data/jmbaur-ssh-keys.nix);
  };
}
