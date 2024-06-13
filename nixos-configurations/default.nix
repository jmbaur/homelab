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
inputs.nixpkgs.lib.mapAttrs (
  directory: _:
  inputs.nixpkgs.lib.nixosSystem {
    modules = [
      (
        # Configuration that we want to be globally applied to all machines
        # _within_ this flake, but not necessarily exported for outside usage
        # as a module.
        { config, ... }:
        {
          assertions = [
            {
              assertion = builtins.elem config.networking.hostName knownVegetables;
              message = "Hostname is not a vegetable! It is impossible to proceed further";
            }
          ];
          networking.hostName = directory;
          sops.defaultSopsFile = ./${directory}/secrets.yaml;
          custom.image = {
            enable = true;
            update = {
              source = "https://update.jmbaur.com/${config.networking.hostName}";
              gpgPubkey = ../data/sysupdate.gpg;
            };
          };
        }
      )
      inputs.self.nixosModules.default
      ./${directory}
    ];
  }
) (inputs.nixpkgs.lib.filterAttrs (_: entryType: entryType == "directory") (builtins.readDir ./.))
