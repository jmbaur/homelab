let
  knownVegetables = [
    "artichoke"
    "asparagus"
    "beetroot"
    "broccoli"
    "cabbage"
    "carrot"
    "cauliflower"
    "celery"
    "fennel"
    "garlic"
    "kale"
    "okra"
    "onion"
    "pea"
    "potato"
    "pumpkin"
    "radish"
    "rhubarb"
    "squash"
    "zucchini"
  ];
in
inputs:

let
  inherit (builtins) attrNames;
  inherit (inputs.nixpkgs.lib)
    const
    filterAttrs
    genAttrs
    ;

  allHosts = attrNames (
    filterAttrs (const (entryType: entryType == "directory")) (builtins.readDir ./.)
  );
in
genAttrs allHosts (
  host:
  inputs.nixpkgs.lib.nixosSystem {
    # extraModules are included in any usage of `noUserModules`, which
    # means all of our custom options will still exist.
    extraModules = [ inputs.self.nixosModules.default ];

    modules = [
      (
        # Opinionated configuration that we want to be applied to all machines
        # _within_ this flake, but not necessarily exported for outside usage
        # as a module.
        { config, lib, ... }:
        {
          _file = "<homelab/nixos-configurations/default.nix>";

          assertions = [
            {
              assertion = builtins.elem config.networking.hostName knownVegetables;
              message = "Hostname is not a vegetable! It is impossible to proceed further.";
            }
          ];

          # Default to the same build platform as our main build server.
          nixpkgs.buildPlatform = lib.mkDefault "x86_64-linux";

          networking.hostName = host;

          sops.defaultSopsFile = ./${host}/secrets.yaml;

          users.users.root.openssh.authorizedKeys.keys = [
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo="
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo="
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDmnCgu1Jbl73bx7ijawfVEIHRFjAJ6qmXmYViGyykyA2DQgR3uzfoe09S9oITgHCIQUA53dy0kjQBhwVZJpXFV1eW+rxKBa024ob1yoBxCg6X5+lhBf5sgIEO48nNuDnYisINdbmxL5QqZjM7QnGukmWR5XjwmI83coWiAgbBueWKM70dxi5UgpBG89/RXgpz3OtEK16ZaW1yWyPwi1AY3xzz5HITUDw4AhhpohI/8uq15eDvgZXJwC9E/j9Frh1HhemWry34/d2RZe1w7l8glMvsEdN1NnfjzjQeZhv0EsbCySpqU3b9e0YMn3hda/FC12V9fuAJckAyh1oPPY2B1O+4nYGcuUv50NNnVB1UsSRKNlL5zHkIBpHB+3jba0tHeo/UUQBafmoTUWZh5k4U3bA2CWZ9N2T0SW632LAFUn5KeZoYgl/v0/uzhsXe87MDvmI869lpaOxbzfM3Mnu/XAPYPraUXdeW8a9fL3R/4f/vPSP/V5VfRzBCNa1AJDSdH5/IwpwqCrlO8woixjRYcknnZLNqkR92iqsNYUTP3+xYHHocRBPcLsuGtdbl81QxW9jtk7Ls9q9A/gMYk4WgiVXtbrmVg3FlNsi0TnjJQgMYnsRen9z904AouQXGf8CrFlmxJvwWlK1RU+Q29+PemjVaTr3vME0HMpyEny0+Wmw=="
          ];

          nix.settings = {
            substituters = [ "https://cache.jmbaur.com" ];
            trusted-public-keys = [ "cache.jmbaur.com-1:qIdQ48kbe/ZGhF+roEt1BJZlrP+mP0lCmoGese1Sb6s=" ];
          };

          custom.common.enable = lib.mkDefault true;
          custom.update = {
            enable = lib.mkDefault (!config.custom.desktop.enable);
            automatic = lib.mkDefault true;
            endpoint = lib.mkDefault "https://hydra.jmbaur.com/job/homelab/main/${config.networking.hostName}.toplevel/latest";
            timestamp = inputs.self.lastModified;
          };

          custom.recovery = {
            enable = lib.mkDefault true;
            endpoint = lib.mkDefault "https://hydra.jmbaur.com/job/homelab/main/${config.networking.hostName}.toplevel/latest";
            extraModule.imports = [
              ./network.nix
              { custom.common.enable = true; }
            ];
          };

          services.yggdrasil = {
            enable = lib.mkDefault true;
            persistentKeys = lib.mkDefault true;
            openMulticastPort = lib.mkDefault true;
            settings.MulticastInterfaces = [
              {
                Regex = ".*";
                Beacon = true;
                Listen = true;
                Port = 9001;
              }
            ];
          };

          networking.firewall.allowedTCPPorts = lib.mkIf (
            config.services.yggdrasil.enable
            && lib.any (
              iface: (iface.Regex or "") == ".*"
            ) config.services.yggdrasil.settings.MulticastInterfaces or [ ]
          ) [ 9001 ];

          custom.yggdrasil.peers = {
            potato.allowAll = true;
            cauliflower.allowAll = true;
            garlic.allowAll = true;
            pea.allowAll = true;
            radish.allowAll = true;
          };

          custom.backup.sender = lib.mkIf config.services.yggdrasil.enable {
            enable = lib.mkDefault true;
            receiver = "artichoke.internal 4000";
          };

          # Only allow SSH from known yggdrasil peers and the LAN, not the
          # entire yggdrasil network or the internet.
          services.openssh.openFirewall = false;
          custom.yggdrasil.allKnownPeers.allowedTCPPorts = config.services.openssh.ports;
          # Ordered last so that the router's bogon network rules drop
          # spoofed private addresses arriving on its WAN interface first.
          networking.firewall.extraInputRules = lib.mkAfter (
            let
              ports = lib.concatMapStringsSep ", " toString config.services.openssh.ports;
            in
            ''
              ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } tcp dport { ${ports} } accept comment "accept SSH from private IPv4 networks"
              ip6 saddr { fe80::/10, fc00::/7 } tcp dport { ${ports} } accept comment "accept SSH from link-local and ULA IPv6 networks"
            ''
          );
        }
      )

      # The entire homelab network
      ./network.nix

      # Backup strategy
      ./backup.nix

      # Metrics collection and dashboards
      ./monitoring.nix

      # Host-specific configuration
      ./${host}
    ];
  }
)
