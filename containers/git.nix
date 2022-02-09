{ config, lib, pkgs, ... }:
{
  environment.etc."cgitrc".text = ''
    about-filter=''${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
    cache-size=1000
    logo-link=/
    remove-suffix=1
    scan-path=${config.services.gitDaemon.basePath}
    source-filter=''${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    # virtual-root=${pkgs.cgit}/cgit
  '';
  services.gitDaemon = {
    enable = true;
    exportAll = true;
    basePath = "/srv/git";
  };
  services.httpd = {
    enable = true;
    extraConfig = ''
      <Directory "${pkgs.cgit}/cgit">
        Options +ExecCGI
        AddHandler cgi-script .cgi
        DirectoryIndex cgit.cgi
        RewriteEngine on
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule (.*) /cgit.cgi/$1 [END,QSA]
        RewriteCond %{QUERY_STRING} service=git-receive-pack
        RewriteRule .* - [END,F]
      </Directory>
    '';
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
