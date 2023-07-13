{ config, pkgs, modulesPath, ... }:
let
  wg = import ../../nixos-modules/mesh-network/inventory.nix;
  gitHome = "/var/lib/git";
  gitShellCommands = "${gitHome}/git-shell-commands";
in
{
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
  virtualisation.amazon-init.enable = false;
  nixpkgs.hostPlatform = "aarch64-linux";
  custom.crossCompile.enable = true;

  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.loader.grub.configurationLimit = 2;

  system.stateVersion = "22.11";

  custom.server.enable = true;
  custom.deployee = {
    enable = true;
    authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.session_secret = { };
    secrets.passwords = { };
    secrets.wg0 = { };
  };

  services.fail2ban = {
    enable = true;
    jails.nginx-botsearch = ''
      enabled      = true
      backend      = systemd
      journalmatch = _SYSTEMD_UNIT=nginx.service + _COMM=nginx
    '';
    jails.nginx-http-auth = ''
      enabled      = true
      backend      = systemd
      journalmatch = _SYSTEMD_UNIT=nginx.service + _COMM=nginx
    '';
  };

  networking = {
    hostName = "www";
    useDHCP = false;
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

  systemd.network.enable = true;
  systemd.network.networks.ethernet = {
    name = "en*";
    DHCP = "yes";
    dhcpV4Config.ClientIdentifier = "mac";
  };

  custom.wg-mesh = {
    enable = true;
    peers.kale = { };
  };

  fileSystems.git = {
    mountPoint = gitHome;
    device = "[${wg.kale.ip}]:/";
    fsType = "nfs";
    options = [ "vers=4" "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };

  users.users.git = {
    home = config.fileSystems.git.mountPoint;
    uid = config.ids.uids.git;
    group = "git";
    shell = pkgs.git;
    openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
  };
  users.groups.git.gid = config.ids.gids.git;

  services.webauthn-tiny = {
    enable = true;
    basicAuthFile = config.sops.secrets.passwords.path;
    sessionSecretFile = config.sops.secrets.session_secret.path;
    relyingParty = {
      id = "jmbaur.com";
      origin = "https://auth.jmbaur.com";
      extraAllowedOrigins = map (vhost: "https://${vhost}") config.services.webauthn-tiny.nginx.protectedVirtualHosts;
    };
    nginx = {
      enable = true;
      virtualHost = "auth.jmbaur.com";
      useACMEHost = "jmbaur.com";
      protectedVirtualHosts = [ "mon.jmbaur.com" ];
    };
  };

  services.journald.enableHttpGateway = true;

  services.fcgiwrap = {
    enable = true;
    inherit (config.services.nginx) user group;
  };

  services.nginx = {
    enable = true;
    statusPage = true;
    commonHttpConfig = ''
      error_log syslog:server=unix:/dev/log;
      access_log syslog:server=unix:/dev/log combined;
    '';
    virtualHosts = {
      # https://grafana.com/tutorials/run-grafana-behind-a-proxy/
      "mon.jmbaur.com" = {
        forceSSL = true;
        useACMEHost = "jmbaur.com";
        locations."/" = {
          proxyPass = "http://[${wg.carrot.ip}]:3000";
          extraConfig = ''
            proxy_set_header Host $host;
          '';
        };
        locations."/api/live" = {
          proxyPass = "http://[${wg.carrot.ip}]:3000";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
          '';
        };
      };
      # https://wiki.archlinux.org/title/Cgit#Using_fcgiwrap
      "git.jmbaur.com" = {
        enableACME = true;
        forceSSL = true;
        extraConfig = ''
          try_files $uri @cgit;
        '';
        root =
          let
            cgit = pkgs.symlinkJoin {
              name = "cgit-custom";
              paths = [ pkgs.cgit-pink ];
              postBuild = ''
                ln -s ${./custom.css} $out/cgit/custom.css
                ln -s ${./favicon.ico} $out/cgit/favicon.ico
              '';
            };
          in
          "${cgit}/cgit";
        locations."~ /.+/(info/refs|git-upload-pack)".extraConfig = ''
          include             ${pkgs.nginx}/conf/fastcgi_params;
          fastcgi_param       SCRIPT_FILENAME     ${pkgs.git}/libexec/git-core/git-http-backend;
          fastcgi_param       PATH_INFO           $uri;
          # fastcgi_param       GIT_HTTP_EXPORT_ALL 1; # don't export all repos
          fastcgi_param       GIT_PROJECT_ROOT    ${config.users.users.git.home};
          fastcgi_param       HOME                ${config.users.users.git.home};
          fastcgi_pass        ${config.services.fcgiwrap.socketType}:${config.services.fcgiwrap.socketAddress};
        '';
        locations."@cgit".extraConfig = ''
          include             ${pkgs.nginx}/conf/fastcgi_params;
          fastcgi_param       SCRIPT_FILENAME $document_root/cgit.cgi;
          fastcgi_param       PATH_INFO       $uri;
          fastcgi_param       QUERY_STRING    $args;
          fastcgi_param       HTTP_HOST       $server_name;
          fastcgi_pass        ${config.services.fcgiwrap.socketType}:${config.services.fcgiwrap.socketAddress};
        '';
      };
      "jmbaur.com" = {
        default = true;
        enableACME = true;
        forceSSL = true;
        serverAliases = [ "www.jmbaur.com" ];
        locations."/" = {
          root = pkgs.linkFarm "root" [
            {
              name = "index.html";
              path = pkgs.writeText "index.html" ''
                <!DOCTYPE html>
                <p>These aren't the droids you're looking for.</p>
              '';
            }
            {
              name = "robots.txt";
              path = pkgs.writeText "robots.txt" ''
                User-agent: * Disallow: /
              '';
            }
          ];
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "jaredbaur@fastmail.com";
    certs."jmbaur.com".extraDomainNames = map (subdomain: "${subdomain}.jmbaur.com") [
      "auth"
      "git"
      "logs"
      "mon"
    ];
  };

  environment.etc."cgitrc".text =
    let
      headInclude = pkgs.writeText "cgit-head-include" ''
        <link rel="stylesheet" type="text/css" href="/custom.css">
      '';
    in
    ''
      # these need to be before `scan-path`
      readme=:README.md
      readme=:readme.md
      readme=:README.mkd
      readme=:readme.mkd
      readme=:README.rst
      readme=:readme.rst
      readme=:README.html
      readme=:readme.html
      readme=:README.htm
      readme=:readme.htm
      readme=:README.txt
      readme=:readme.txt
      readme=:README
      readme=:readme
      strict-export=git-daemon-export-ok
      remove-suffix=1
      scan-hidden-path=0
      snapshots=tar.gz tar.bz2 zip
      about-filter=${pkgs.cgit-pink}/lib/cgit/filters/about-formatting.sh
      source-filter=${pkgs.cgit-pink}/lib/cgit/filters/syntax-highlighting.py
      section-from-path=1
      clone-url=https://git.jmbaur.com/$CGIT_REPO_URL

      scan-path=${config.users.users.git.home}
      repository-sort=age
      branch-sort=age
      root-title=git.jmbaur.com
      root-desc=These aren't the droids you're looking for.
      side-by-side-diffs=0
      enable-index-owner=0
      head-include=${headInclude}
      css=/cgit.css
      favicon=/favicon.ico
      logo=
      enable-http-clone=1
      cache-root=/var/cache/cgit
      cache-size=1000
      robots=noindex, nofollow
      virtual-root=/
    '';

  systemd.tmpfiles.rules = [
    "d /var/cache/cgit - ${config.services.nginx.user} ${config.services.nginx.group} -"
  ];

  fileSystems.gitShellCommands = {
    mountPoint = gitShellCommands;
    device = toString pkgs.git-shell-commands;
    options = [ "bind" ];
  };

}
