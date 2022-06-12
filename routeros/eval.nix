{ nixpkgs
, configurationFile
, inventoryFile
, secretsFile
}:
with import nixpkgs { };
let
  configuration = (callPackage configurationFile { }) {
    inventory = lib.importJSON inventoryFile;
    secrets = lib.importJSON secretsFile;
  };
in
writeText "${configuration.name}.rsc" ''
  ${lib.concatStringsSep "\n" configuration.commands}
''
