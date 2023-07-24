{ lib, fetchFromGitHub }:
let
  source = lib.importJSON ./stevenblack-blocklist-source.json;
in
fetchFromGitHub {
  pname = "stevenblack-blocklist";
  version = builtins.substring 0 7 source.rev;
  owner = "stevenblack";
  repo = "hosts";
  inherit (source) rev sha256;
}
