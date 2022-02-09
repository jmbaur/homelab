{ config, lib, pkgs, ... }: {
  services.gitDaemon = {
    enable = true;
    exportAll = true;
    basePath = "/srv/git";
  };
  environment.etc."cgitrc".text = ''
    source-filter=''${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    about-filter=''${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
    cache-size=1000
    scan-path=${config.services.gitDaemon.basePath}
  '';
  services.caddy = {
    enable = true;
    virtualHosts."git.jmbaur.com" = {
      listenAddresses = [ "127.0.0.1" "::1" ];
      extraConfig = ''
        root ${pkgs.cgit}/cgit
        cgi {
          match /
          exec  ${pkgs.cgit}/cgit/cgit.cgi
          except /cgit.png /favicon.ico /cgit.css /robots.txt
        }
      '';
    };
  };
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
