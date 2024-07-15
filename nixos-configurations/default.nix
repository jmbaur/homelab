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
        # Configuration that we want to be globally applied to all machines
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

          # Not actually used unless `config.sops.secrets != { }`, so it's fine
          # if this file doesn't exist.
          sops.defaultSopsFile = ./${host}/secrets.yaml;

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

          custom.wgNetwork = {
            ulaHextets = [
              64779
              57458
              54680
            ];

            nodes = lib.genAttrs allHosts (name: {
              # These are only used if `peer = true`, so we can set some values
              # here that enforce structure in the repo.
              publicKey = readFile "wg-${host}.pubkey does not exist for ${name}" ./${name}/wg-${host}.pubkey;
              privateKey.file = config.sops.secrets."wg-${name}".path;
            });
          };

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
