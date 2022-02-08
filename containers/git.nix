{ config, lib, pkgs, ... }: {
  services.gitDaemon = {
    enable = true;
    exportAll = true;
    basePath = "/srv/git";
  };
  services.gitweb.gitwebTheme = true;
  services.nginx = {
    enable = true;
    gitweb.enable = true;
  };
  networking.firewall.allowedTCPPorts = [ 80 ];
  networking.interfaces.mv-trusted.useDHCP = true;
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  users.users.git = {
    home = config.services.gitDaemon.basePath;
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../data/jmbaur-ssh-keys.nix);
  };
}
