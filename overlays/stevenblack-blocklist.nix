{ lib, fetchgit }:
let
  source = lib.importJSON ./stevenblack-blocklist-source.json;
in
fetchgit { inherit (source) url rev hash fetchSubmodules; }
