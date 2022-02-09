{ config, lib, pkgs, ... }: {
  services.gitDaemon = {
    enable = true;
    exportAll = true;
    basePath = "/srv/git";
  };
  services.caddy = {
    enable = true;
  };
  # services.lighttpd = {
  #   enable = true;
  #   cgit = {
  #     enable = true;
  #     subdir = "";
  #     configText = ''
  #       source-filter=${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
  #       about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
  #       cache-size=1000
  #       scan-path=${config.services.gitDaemon.basePath}
  #     '';
  #   };
  # };
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
