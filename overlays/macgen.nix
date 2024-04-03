{
  writeShellScriptBin,
  openssl,
  gnused,
}:
writeShellScriptBin "macgen" ''
  ${openssl}/bin/openssl rand -hex 6 | ${gnused}/bin/sed 's/\(..\)/\1:/g; s/:$//'
''
