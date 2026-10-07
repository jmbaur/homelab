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
    "leek"
    "okra"
    "onion"
    "pea"
    "potato"
    "pumpkin"
    "radish"
    "rhubarb"
    "squash"
    "turnip"
    "zucchini"
  ];
in
inputs:

let
  inherit (builtins) elem;
  inherit (inputs.nixpkgs.lib)
    const
    filterAttrs
    flip
    getAttrs
    hasSuffix
    mapAttrs
    optionalAttrs
    recursiveUpdate
    systems
    ;
  inherit (inputs.nixpkgs.lib.attrsets) unionOfDisjoint;
  isLinux = system: (systems.elaborate system).isLinux;
  onlyLinuxOutput = filterAttrs (flip (const isLinux));

  onlyVegetables = mapAttrs (
    host: jobs:
    if elem host knownVegetables then
      jobs
    else
      throw "Hostname '${host}' is not a vegetable! It is impossible to proceed further."
  );
in
# TODO(jared): put nixos configurations in their own attrset
# NixOS and MixOS configurations share one namespace of hostnames, so this
# fails to evaluate if a hostname is used by both.
onlyVegetables (
  unionOfDisjoint
    (mapAttrs (
      _: nixosConfig:
      recursiveUpdate
        {
          inherit (nixosConfig.config.system.build) toplevel;
        }
        (
          optionalAttrs nixosConfig.config.custom.recovery.enable {
            inherit (nixosConfig.config.system.build) recoveryImage;
          }
        )
    ) inputs.self.nixosConfigurations)
    (
      mapAttrs (const (
        { config, ... }: getAttrs config.custom.hydraJobs config.system.build
      )) inputs.self.mixosConfigurations
    )
)
// recursiveUpdate (onlyLinuxOutput inputs.self.packages) (onlyLinuxOutput inputs.self.checks)
// {
  # The stub home configuration is not impure
  homeConfigurations = filterAttrs (const (drv: isLinux drv.system)) (
    mapAttrs (const (homeConfig: homeConfig.activationPackage)) (
      filterAttrs (flip (const (hasSuffix "-stub"))) inputs.self.homeConfigurations
    )
  );
}
