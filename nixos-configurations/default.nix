let
  knownVegetables = [
    "artichoke"
    "asparagus"
    "beetroot"
    "fennel"
    "garlic"
    "pea"
    "pumpkin"
    "rhubarb"
    "squash"
    "zucchini"
    "broccoli"
    "cabbage"
    "carrot"
    "cauliflower"
    "celery"
    "kale"
    "onion"
    "potato"
    "radish"
  ];
in
inputs:

let
  allHosts = builtins.attrNames (
    inputs.nixpkgs.lib.filterAttrs (_: entryType: entryType == "directory") (builtins.readDir ./.)
  );
in

inputs.nixpkgs.lib.genAttrs allHosts (
  host:
  inputs.nixpkgs.lib.nixosSystem {
    # extraModules are included in any usage of `noUserModules`, which means all of our custom options will still exist.
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

          networking.hostName = host;

          sops.defaultSopsFile = ./${host}/secrets.yaml;

          users.users.root.openssh.authorizedKeys.keys = [
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo="
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo="
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDmnCgu1Jbl73bx7ijawfVEIHRFjAJ6qmXmYViGyykyA2DQgR3uzfoe09S9oITgHCIQUA53dy0kjQBhwVZJpXFV1eW+rxKBa024ob1yoBxCg6X5+lhBf5sgIEO48nNuDnYisINdbmxL5QqZjM7QnGukmWR5XjwmI83coWiAgbBueWKM70dxi5UgpBG89/RXgpz3OtEK16ZaW1yWyPwi1AY3xzz5HITUDw4AhhpohI/8uq15eDvgZXJwC9E/j9Frh1HhemWry34/d2RZe1w7l8glMvsEdN1NnfjzjQeZhv0EsbCySpqU3b9e0YMn3hda/FC12V9fuAJckAyh1oPPY2B1O+4nYGcuUv50NNnVB1UsSRKNlL5zHkIBpHB+3jba0tHeo/UUQBafmoTUWZh5k4U3bA2CWZ9N2T0SW632LAFUn5KeZoYgl/v0/uzhsXe87MDvmI869lpaOxbzfM3Mnu/XAPYPraUXdeW8a9fL3R/4f/vPSP/V5VfRzBCNa1AJDSdH5/IwpwqCrlO8woixjRYcknnZLNqkR92iqsNYUTP3+xYHHocRBPcLsuGtdbl81QxW9jtk7Ls9q9A/gMYk4WgiVXtbrmVg3FlNsi0TnjJQgMYnsRen9z904AouQXGf8CrFlmxJvwWlK1RU+Q29+PemjVaTr3vME0HMpyEny0+Wmw=="
          ];

          nix.settings.substituters = [ "https://cache.jmbaur.com" ];
          nix.settings.trusted-public-keys = [
            "cache.jmbaur.com:C3ku8BNDXgfTO7dNHK+eojm4uy7Gvotwga+EV0cfhPQ="
          ];

          custom.common.enable = lib.mkDefault true;
          custom.update = {
            enable = lib.mkDefault true;
            endpoint = lib.mkDefault "https://update.jmbaur.com/${config.networking.hostName}";
          };
          custom.recovery.enable = lib.mkDefault true;
        }
      )
      (
        { config, lib, ... }:

        let
          ulaHextets = [
            64779
            57458
            54680
          ];

          ulaNetworkSegments =
            map (hextet: lib.toLower (lib.toHexString hextet)) ulaHextets
            ++ lib.genList (_: "0000") (4 - (lib.length ulaHextets));

          hextetOffsets = lib.genList (x: x * 4) 4;

          tincHostSubnet =
            hostName:
            let
              hostHash = builtins.hashString "sha256" hostName;
              hostSegments = map (x: lib.substring x 4 hostHash) hextetOffsets;
            in
            {
              address = lib.concatStringsSep ":" (ulaNetworkSegments ++ hostSegments);
              prefixLength = 128;
            };

          useTinc = builtins.pathExists ./${config.networking.hostName}/tinc.ed25519;
        in
        (lib.mkIf useTinc {
          sops.secrets = {
            tinc.owner = config.users.users.tinc-jmbaur.name;
          };

          systemd.network = {
            enable = true;
            networks."10-tinc-jmbaur" = {
              matchConfig.Name = "tinc.jmbaur";
              address =
                let
                  inherit (tincHostSubnet config.networking.hostName) address;
                in
                [ "${address}/64" ];
            };
          };

          networking.extraHosts = lib.concatLines (
            lib.flatten (
              lib.mapAttrsToList (
                host: hostSettings: map (subnet: "${subnet.address} ${host}.internal") hostSettings.subnets
              ) config.services.tinc.networks.jmbaur.hostSettings
            )
          );

          # TODO(jared): more finegrained rules
          networking.firewall = {
            extraInputRules = ''
              iifname tinc.jmbaur accept
            '';
            extraForwardRules = ''
              iifname tinc.jmbaur accept
            '';
          };

          services.tinc.networks.jmbaur = {
            ed25519PrivateKeyFile = config.sops.secrets.tinc.path;
            settings.ConnectTo = lib.mkIf (config.networking.hostName != "squash") "squash";
            hostSettings = lib.mkMerge [
              { squash.addresses = [ { address = "squash.jmbaur.com"; } ]; }
              (lib.genAttrs (lib.filter (host: builtins.pathExists ./${host}/tinc.ed25519) allHosts) (host: {
                settings.Ed25519PublicKey = lib.fileContents ./${host}/tinc.ed25519;
                subnets = [
                  (tincHostSubnet host)
                ];
              }))
            ];
          };
        })
      )
      # Host-specific configuration
      ./${host}
    ];
  }
)
