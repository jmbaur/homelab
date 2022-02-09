{ config, lib, pkgs, ... }:
{
  services.gitDaemon = {
    enable = true;
    exportAll = true;
    basePath = "/srv/git";
  };
  services.lighttpd = {
    enable = true;
    cgit.enable = true;
    cgit.configText = ''
      about-filter=''${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
      cache-size=1000
      logo-link=/
      remove-suffix=1
      scan-path=${config.services.gitDaemon.basePath}
      source-filter=''${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
      # virtual-root=${pkgs.cgit}/cgit
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
  users.users.lighttpd.extraGroups = [ config.services.gitDaemon.group ];
}
