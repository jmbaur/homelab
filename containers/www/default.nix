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
  cgitrc = pkgs.writeText "cgitrc" ''
    cache-size=1000
    cache-root=/var/cache/cgit
    about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
    source-filter=${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    enable-http-clone=1
    clone-url=https://$HTTP_HOST$SCRIPT_NAME$CGIT_REPO_URL
    snapshots=tar.gz zip
    remove-suffix=1
    scan-path=${config.services.gitDaemon.basePath}
  '';
  vhostSsl = {
    forceSSL = true;
    sslCertificate = "/var/lib/nginx/jmbaur.com.cert";
    sslCertificateKey = "/var/lib/nginx/jmbaur.com.key";
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
  # services.prometheus.exporters.nginx = {
  #   enable = true;
  #   openFirewall = false;
  # };
  boot.isContainer = true;
  services.nginx.statusPage = true;
  networking = {
    useHostResolvConf = false;
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
  services.fcgiwrap.enable = true;
  services.nix-serve = {
    enable = true;
    openFirewall = false;
    secretKeyFile = "/var/lib/nix-serve/cache-priv-key.pem";
  };
  services.gitDaemon = {
    enable = true;
    exportAll = true;
    basePath = config.users.users.jared.home;
  };
  services.nginx = {
    enable = true;
    virtualHosts."_" =
      let
        index = pkgs.runCommandNoCC "index" { } ''
          mkdir -p $out
          cat > $out/index.html << EOF
          <h1>These aren't the droids you're looking for.</h1>
          EOF
        '';
      in
      mkVhost {
        default = true;
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
  system.userActivationScripts.git-shell-commands.text = ''
    ln -sfT ${commands}/bin $HOME/git-shell-commands
  '';
  users.users.jared = {
    isNormalUser = true;
    shell = "${pkgs.git}/bin/git-shell";
    description = "Jared Baur";
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../../data/jmbaur-ssh-keys.nix);
  };
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };
  services.fail2ban.enable = true;
}
