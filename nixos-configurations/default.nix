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

          sops.secrets.wg = lib.mkIf config.custom.wgNetwork.isEnabled {
            mode = "0640";
            owner = "root";
            inherit (config.users.users.systemd-network) group;
            reloadUnits = [ config.systemd.services.systemd-networkd.name ];
          };

          custom.wgNetwork = {
            privateKey = lib.mkIf config.custom.wgNetwork.isEnabled { file = config.sops.secrets.wg.path; };
            ulaHextets = [
              64779
              57458
              54680
            ];
            nodes = lib.genAttrs allHosts (host: {
              pubkey = readFile "wg.pubkey does not exist for ${host}" ./${host}/wg.pubkey;

              # NOTE: This is dependent on perspective of the peer initiating the
              # connection. We default to the scenario where peers are on the
              # same LAN and can communicate via mDNS, however this can be
              # modified with the per-node `hostname` NixOS option.
              hostname = lib.mkDefault "${host}.local";
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
