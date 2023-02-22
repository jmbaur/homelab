{ config, lib, pkgs, modulesPath, ... }:
let
  wg = import ./wg.nix;
in
{
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
  virtualisation.amazon-init.enable = false;

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
    secrets = {
      session_secret = { };
      passwords = { };
      "wg/www/www" = {
        mode = "0640";
        group = config.users.groups.systemd-network.name;
      };
    };
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
    firewall = {
      allowedTCPPorts = [ 80 443 ];
      allowedUDPPorts = [ config.networking.wireguard.interfaces.www.listenPort ];
    };
    wireguard.interfaces.www = {
      privateKeyFile = config.sops.secrets."wg/www/www".path;
      listenPort = 51820;
      ips = [ (wg.www.ip + "/64") ];
      peers = [
        { allowedIPs = [ (wg.kale.ip + "/128") ]; publicKey = wg.kale.publicKey; }
        { allowedIPs = [ (wg.rhubarb.ip + "/128") ]; publicKey = wg.rhubarb.publicKey; }
        { allowedIPs = [ (wg.artichoke.ip + "/128") ]; publicKey = wg.artichoke.publicKey; }
      ];
    };
  };

  fileSystems.git = {
    mountPoint = "/var/lib/git";
    device = "[${wg.kale.ip}]:/";
    fsType = "nfs";
    options = [ "vers=4" ];
  };

  users.users.git = {
    home = config.fileSystems.git.mountPoint;
    uid = config.ids.uids.git;
    group = "git";
    shell = pkgs.git;
    openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
  };
  users.groups.git.gid = config.ids.gids.git;

  home-manager.users.git = { pkgs, ... }: {
    home.file = builtins.listToAttrs
      (map (script: lib.nameValuePair "git-shell-commands/${script.name}" { source = script; }) [
        (pkgs.writeShellScript "list" ''
          for dir in $(find "$PWD" -maxdepth 1 -type d); do
          	cd "$dir" || return
          	if [ "$(${pkgs.git}/bin/git rev-parse --is-bare-repository 2>/dev/null)" == "true" ]; then
          		basename "$PWD"
          	fi
          done
        '')
        (pkgs.writeShellScript "create" ''
          if test -z "$1"; then
                  echo "Usage: $(basename $0) <name>"
                  echo "create a repository"
                  exit 1
          fi
          new_repo="''${HOME}/''${1}.git"
          ${pkgs.git}/bin/git init --bare --initial-branch=main "$new_repo" >/dev/null
          touch "''${new_repo}/git-daemon-export-ok"
          read -p "Description: " description
          echo "$description" > "''${new_repo}/description"
          echo "$new_repo"
        '')
        (pkgs.writeShellScript "create-private" ''
          if test -z "$1"; then
                  echo "Usage: $(basename $0) <name>"
                  echo "create a private repository"
                  exit 1
          fi
          new_repo=$($HOME/git-shell-commands/create "$@")
          rm "''${new_repo}/git-daemon-export-ok"
          echo "$new_repo"
        '')
        (pkgs.writeShellScript "delete" ''
          if test -z "$1"; then
                  echo "Usage: $(basename $0) <name>"
                  echo "delete a repository"
                  exit 1
          fi
          path="''${HOME}/''${1}.git"
          echo "Deleting $path"
          rm -r "$path"
        '')
      ]);
  };

  services.webauthn-tiny =
    {
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
        protectedVirtualHosts = [ "logs.jmbaur.com" "mon.jmbaur.com" ];
      };
    };

  services.journald.enableHttpGateway = true;
  services.fcgiwrap.enable = true;
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
          proxyPass = "http://[${wg.rhubarb.ip}]:3000";
          extraConfig = ''
            proxy_set_header Host $host;
          '';
        };
        locations."/api/live" = {
          proxyPass = "http://[${wg.rhubarb.ip}]:3000";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
          '';
        };
      };
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
      "logs.jmbaur.com" =
        let
          logHosts = [ "artichoke" "rhubarb" "www" "kale" ];
          locationBlocks = {
            locations = lib.listToAttrs (map
              (host: lib.nameValuePair "/${host}/" {
                proxyPass = "http://[${wg.${host}.ip}]:19531/";
              })
              logHosts);
          };
        in
        lib.recursiveUpdate locationBlocks {
          forceSSL = true;
          useACMEHost = "jmbaur.com";
          locations."/" = {
            root = pkgs.linkFarm "root" [
              {
                name = "index.html";
                path = pkgs.writeText "index.html"
                  ("<!DOCTYPE html>"
                    + (lib.concatMapStrings (host: ''<a href="/${host}/browse">${host}</a><br />'') logHosts));
              }
              { name = "favicon.ico"; path = "${./logs_favicon.ico}"; }
            ];
          };
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
      strict-export=git-daemon-export-ok
      scan-hidden-path=0
      snapshots=tar.gz tar.bz2 zip

      scan-path=${config.users.users.git.home}
      source-filter=${pkgs.cgit-pink}/lib/cgit/filters/syntax-highlighting.py
      remove-suffix=1
      root-title=git.jmbaur.com
      root-desc=These aren't the droids you're looking for.
      side-by-side-diffs=1
      enable-index-owner=0
      head-include=${headInclude}
      css=/cgit.css
      favicon=/favicon.ico
      logo=/cgit.png
      enable-http-clone=1
      robots=noindex, nofollow
      virtual-root=/
    '';
}
