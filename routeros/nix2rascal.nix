{ callPackage
, path
, lib
, nix
, sops
, writeShellScriptBin
, writeText
}:
{ inventoryFile, secretsFile, ... }:

configurationFile:
let
  nix2rascalEval = writeShellScriptBin "nix2rascalEval" ''
    ${nix}/bin/nix build \
      --impure \
      --arg nixpkgs ${path} \
      --arg configurationFile ${configurationFile} \
      --arg inventoryFile ${inventoryFile} \
      --arg secretsFile "$1" \
      --file ${./eval.nix} \
      --print-out-paths
  '';
in
writeShellScriptBin "nix2rascal" ''
  ${sops}/bin/sops exec-file --output-type=json ${secretsFile} "${nix2rascalEval}/bin/nix2rascalEval {}"
''
