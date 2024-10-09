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
  readFile =
    msg: file:
    if !(builtins.pathExists file) then
      builtins.throw msg
    else
      builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile file);

  allHosts = builtins.attrNames (
    inputs.nixpkgs.lib.filterAttrs (_: entryType: entryType == "directory") (builtins.readDir ./.)
  );
in

inputs.nixpkgs.lib.genAttrs allHosts (
  host:
  inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.self.nixosModules.default
      (
        # Opinionated configuration that we want to be applied to all machines
        # _within_ this flake, but not necessarily exported for outside usage
        # as a module.
        { config, lib, ... }:
        {
          assertions = [
            {
              assertion = builtins.elem config.networking.hostName knownVegetables;
              message = "Hostname is not a vegetable! It is impossible to proceed further.";
            }
          ];

          networking.hostName = host;

          # NOTE: We opt out of baking the sops file into the nixos closure so
          # that we don't have to incur the cost of a rebuild if we need to do
          # something as simple as rolling the value of a secret.
          #
          # TODO(jared): we should write something that actually performs
          # validation of the sops contents, since we don't get to take
          # advantage of it here.
          sops.defaultSopsFile = "/etc/sops.yaml";
          sops.validateSopsFiles = false;

          system.image.version = readFile "/.version does not exist" ../.version;

          sops.secrets = lib.mapAttrs' (name: nodeConfig: {
            name = "wg-${name}";
            value = lib.mkIf nodeConfig.peer {
              mode = "0640";
              owner = "root";
              inherit (config.users.users.systemd-network) group;
              reloadUnits = [ config.systemd.services.systemd-networkd.name ];
            };
          }) config.custom.wgNetwork.nodes;

          custom.wgNetwork = lib.mkMerge [
            {
              ulaHextets = [
                64779
                57458
                54680
              ];

              nodes = lib.genAttrs allHosts (name: {
                # These are only used if `peer = true`, so we can set some
                # values here that enforce structure in the repo.
                publicKey = readFile "wg-${host}.pubkey does not exist for ${name}" ./${name}/wg-${host}.pubkey;
                privateKey.file = config.sops.secrets."wg-${name}".path;
              });
            }
            {
              # Allow cauliflower to SSH to any hosts in the overlay network
              nodes.cauliflower.allowedTCPPorts = [ 22 ];
            }
          ];

          users.users.root.openssh.authorizedKeys.keys = [
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo="
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo="
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDmnCgu1Jbl73bx7ijawfVEIHRFjAJ6qmXmYViGyykyA2DQgR3uzfoe09S9oITgHCIQUA53dy0kjQBhwVZJpXFV1eW+rxKBa024ob1yoBxCg6X5+lhBf5sgIEO48nNuDnYisINdbmxL5QqZjM7QnGukmWR5XjwmI83coWiAgbBueWKM70dxi5UgpBG89/RXgpz3OtEK16ZaW1yWyPwi1AY3xzz5HITUDw4AhhpohI/8uq15eDvgZXJwC9E/j9Frh1HhemWry34/d2RZe1w7l8glMvsEdN1NnfjzjQeZhv0EsbCySpqU3b9e0YMn3hda/FC12V9fuAJckAyh1oPPY2B1O+4nYGcuUv50NNnVB1UsSRKNlL5zHkIBpHB+3jba0tHeo/UUQBafmoTUWZh5k4U3bA2CWZ9N2T0SW632LAFUn5KeZoYgl/v0/uzhsXe87MDvmI869lpaOxbzfM3Mnu/XAPYPraUXdeW8a9fL3R/4f/vPSP/V5VfRzBCNa1AJDSdH5/IwpwqCrlO8woixjRYcknnZLNqkR92iqsNYUTP3+xYHHocRBPcLsuGtdbl81QxW9jtk7Ls9q9A/gMYk4WgiVXtbrmVg3FlNsi0TnjJQgMYnsRen9z904AouQXGf8CrFlmxJvwWlK1RU+Q29+PemjVaTr3vME0HMpyEny0+Wmw=="
          ];

          custom.image = {
            enable = true;
            update = {
              source = "https://update.jmbaur.com/${config.networking.hostName}";
              gpgPubkey = ../data/sysupdate.gpg;
            };
          };
        }
      )
      # Host-specific configuration
      ./${host}
    ];
  }
)
