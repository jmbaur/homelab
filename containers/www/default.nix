{ config, lib, pkgs, ... }:
let
  no-interactive-login = pkgs.writeShellApplication {
    name = "no-interactive-login";
    runtimeInputs = [ ];
    text = ''
      printf '%s\n' "Hi $USER! You've successfully authenticated, but I do not"
      printf '%s\n' "provide interactive shell access."
      exit 128
    '';
  };
  create-repo = pkgs.writeShellApplication rec {
    name = "create-repo";
    runtimeInputs = [ pkgs.git ];
    text = ''
      name=''${1:-}
      description=''${2:-}

      if [ -z "$name" ]; then
        echo "no repo name provided, exiting"
        echo "usage: ${name} \"<my-repo-name>\" \"<my-repo-description>\""
        exit 1
      fi

      final_name=
      case "$name" in
      *.git$)
        final_name="''${name}";;
      *)
        final_name="''${name}.git";;
      esac

      full_path="''${HOME}/''${final_name}"

      if [ -d "$full_path" ]; then
        echo "repo $final_name already exists, exiting"
        exit 2
      fi

      git init --bare --initial-branch main "$full_path"

      if [ -n "$description" ]; then
        echo "$description" > "''${full_path}/description"
      fi
    '';
  };
  commands = pkgs.symlinkJoin {
    name = "git-shell-commands-environment";
    paths = [ create-repo ];
  };
  cgit-cache-root = "/var/cache/cgit";
  cgitrc = pkgs.writeText "cgitrc" ''
    cache-size=1000
    cache-root=${cgit-cache-root}
    about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
    source-filter=${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    enable-index-owner=0
    enable-http-clone=1
    clone-url=https://$HTTP_HOST$SCRIPT_NAME$CGIT_REPO_URL
    snapshots=tar.gz zip
    root-title=git.jmbaur.com
    root-desc="Jared's Git Repositories"
    remove-suffix=1
    scan-path=${config.services.gitDaemon.basePath}
  '';
  vhostSsl = {
    forceSSL = true;
    useACMEHost = "jmbaur.com";
  };
  vhostLogging = {
    extraConfig = ''
      error_log syslog:server=unix:/dev/log;
      access_log syslog:server=unix:/dev/log combined;
    '';
  };
  mkVhost = settings: settings // vhostSsl // vhostLogging;
in
{
  boot.isContainer = true;
  networking = {
    useDHCP = false;
    useHostResolvConf = false;
    hostName = "www";
    defaultGateway.address = "192.168.10.1";
    defaultGateway.interface = "mv-pubwan";
    nameservers = lib.singleton "192.168.10.1";
    domain = "home.arpa";
    interfaces.mv-pubwan.ipv4.addresses = [{
      address = "192.168.10.11";
      prefixLength = 24;
    }];
    interfaces.mv-pubwan.ipv6.addresses = [{
      address = "2001:470:f001:10::11";
      prefixLength = 64;
    }];
    firewall.allowedTCPPorts = [ 80 443 ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/acme 700 acme acme -"
    "d ${cgit-cache-root} 700 ${config.services.fcgiwrap.user} ${config.services.fcgiwrap.group} -"
  ];
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    secrets = {
      "cache-priv-key.pem" = {
        owner = config.systemd.services.nix-serve.serviceConfig.User;
        group = config.systemd.services.nix-serve.serviceConfig.Group;
      };
      "cloudflare" = {
        owner = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "jaredbaur@fastmail.com";
    certs."jmbaur.com" = {
      domain = "*.jmbaur.com";
      dnsProvider = "cloudflare";
      credentialsFile = "/run/secrets/cloudflare";
      dnsPropagationCheck = true;
      group = config.services.nginx.group;
    };
  };
  systemd.services.nix-serve = {
    serviceConfig.DynamicUser = lib.mkForce false;
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };
  users.users.nix-serve = {
    isSystemUser = true;
    group = config.users.groups.nix-serve.name;
  };
  users.groups.nix-serve = { };
  users.users.nginx.extraGroups = [ config.users.users.git.group ];
  systemd.services.nginx = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };
  services.prometheus.exporters.nginx = {
    enable = true;
    openFirewall = false;
  };
  services.fcgiwrap = {
    enable = true;
    user = config.services.gitDaemon.user;
    group = config.services.gitDaemon.group;
  };
  services.nix-serve = {
    enable = true;
    openFirewall = false;
    secretKeyFile = "/run/secrets/cache-priv-key.pem";
  };
  services.gitDaemon = {
    enable = true;
    exportAll = true;
    basePath = "/srv/git";
  };
  services.nginx = {
    enable = true;
    statusPage = true;
    virtualHosts."_" =
      let
        index = pkgs.runCommandNoCC "index" { } ''
          mkdir -p $out
          cat > $out/index.html << EOF
          <!DOCTYPE html>
          These aren't the droids you're looking for.
          EOF
        '';
      in
      mkVhost {
        default = true;
        serverAliases = [ "www" ];
        locations."/" = {
          root = index;
          index = "index.html";
        };
      };
    virtualHosts."cache.jmbaur.com" = mkVhost {
      serverAliases = [ "cache" ];
      locations."/".extraConfig = ''
        proxy_pass http://localhost:${toString config.services.nix-serve.port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
    virtualHosts."git.jmbaur.com" = mkVhost {
      serverAliases = [ "git" ];
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
          fastcgi_pass unix:${config.services.fcgiwrap.socketAddress};
        '';
      };
    };
  };
  system.activationScripts.git-shell-commands.text = ''
    ln -sfT ${commands}/bin ${config.services.gitDaemon.basePath}/git-shell-commands
    chown -R ${config.users.users.git.name}:${config.users.users.git.group} ${config.users.users.git.home}
  '';
  users.users.git = {
    isSystemUser = true;
    home = config.services.gitDaemon.basePath;
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../../data/jmbaur-ssh-keys.nix);
  };
  services.openssh = {
    enable = true;
    passwordAuthentication = lib.mkForce false;
    startWhenNeeded = false; # needed to automatically create host keys
  };
  services.fail2ban.enable = true;
}
