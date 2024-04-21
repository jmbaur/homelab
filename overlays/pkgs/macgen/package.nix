{ writers }:
writers.writeRustBin "macgen" { } (builtins.readFile ./macgen.rs)
# writeShellScriptBin "macgen" ''
#   ${openssl}/bin/openssl rand -hex 6 | ${gnused}/bin/sed 's/\(..\)/\1:/g; s/:$//'
# ''
