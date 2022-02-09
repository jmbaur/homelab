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
  networking = {
    firewall.allowedTCPPorts = [ 80 ];
    interfaces.mv-trusted.useDHCP = true;
  };
  users.users = {
    # "${config.services.fcgiwrap.user}".extraGroups = [ config.services.gitDaemon.group ];
    git = {
      home = config.services.gitDaemon.basePath;
      createHome = true;
      shell = "${pkgs.git}/bin/git-shell";
      openssh.authorizedKeys.keyFiles = lib.singleton (import ../data/jmbaur-ssh-keys.nix);
    };
  };
  services.gitDaemon = {
    enable = true;
    exportAll = true;
    basePath = "/srv/git";
  };
  services.fcgiwrap = {
    enable = true;
  };
  services.nginx = {
    enable = true;
    virtualHosts.localhost = {
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
          fastcgi_pass unix:${config.services.fcgiwrap.socketAddress};
        '';
      };
    };
  };
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };
}
