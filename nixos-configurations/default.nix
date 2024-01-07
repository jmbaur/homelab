inputs:
inputs.nixpkgs.lib.mapAttrs
  (directory: _:
  inputs.nixpkgs.lib.nixosSystem {
    modules = [
      { networking.hostName = directory; }
      inputs.self.nixosModules.default
      ./${directory}
    ];
  })
  (inputs.nixpkgs.lib.filterAttrs
    (_: entryType: entryType == "directory")
    (builtins.readDir ./.))
