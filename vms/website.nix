{ config, lib, pkgs, inventory, inputs, ... }:
let
  vhostSsl = {
    forceSSL = true;
    useACMEHost = inventory.tld;
  };
  vhostLogging = {
    extraConfig = ''
      error_log syslog:server=unix:/dev/log;
      access_log syslog:server=unix:/dev/log combined;
    '';
  };
  mkVhost = settings: settings // vhostLogging;
in
{
  system.stateVersion = "22.05";
  networking = {
    hostName = "website";
    useDHCP = false;
    useNetworkd = true;
    firewall.allowedTCPPorts = [ 80 443 ];
  };
  systemd.network.networks.en = with inventory.networks.pubwan; {
    name = "en*";
    networkConfig = {
      Gateway = [
        hosts.broccoli.ipv4
        hosts.broccoli.ipv6.gua
        hosts.broccoli.ipv6.ula
      ];
      DNS = [
        hosts.broccoli.ipv4
        hosts.broccoli.ipv6.gua
        hosts.broccoli.ipv6.ula
      ];
      Address = [
        "${hosts.website.ipv4}/${toString ipv4Cidr}"
        "${hosts.website.ipv6.gua}/${toString ipv6Cidr}"
        "${hosts.website.ipv6.ula}/${toString ipv4Cidr}"
      ];
    };
  };
  microvm = {
    hypervisor = "qemu";
    mem = 512;
    vcpu = 2;
    shares = [{
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    }];
    interfaces = [{
      type = "tap";
      id = "vm-" + config.networking.hostName;
      mac = "b4:b6:76:00:00:02";
    }];
  };

  services.nginx = {
    enable = true;
    statusPage = true;
    virtualHosts._ = mkVhost {
      default = true;
      serverAliases = [ inventory.tld "www.${inventory.tld}" ];
      root = inputs.blog.packages.${config.nixpkgs.localSystem.system}.default;
      locations."/" = {
        index = "index.html";
        tryFiles = "$uri $uri/ =404";
      };
    };
  };

  # TODO(jared): shouldn't need this
  # systemd.tmpfiles.rules = [ "d /var/lib/acme 700 acme acme -" ];
  security.acme = {
    acceptTerms = true;
    defaults.email = "jaredbaur@fastmail.com";
    # certs.${inventory.tld} = {
    #   domain = "*.${inventory.tld}";
    #   dnsProvider = "cloudflare";
    #   credentialsFile = config.sops.secrets.cloudflare.path;
    #   dnsPropagationCheck = true;
    #   group = config.services.nginx.group;
    # };
  };
}
