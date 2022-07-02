{ path
, nix
, rage
, writeShellScriptBin
, inventoryFile
, configurationFile
, ...
}:
writeShellScriptBin "secretsWrapper" ''
  file=$(mktemp)
  ${rage}/bin/rage --decrypt --identity $1 -o $file $2

  ${nix}/bin/nix build \
    --impure \
    --no-link \
    --print-out-paths \
    --arg path ${path} \
    --arg secretFile $file \
    --arg inventoryFile ${inventoryFile} \
    --file ${configurationFile}

  shred -u $file
''
