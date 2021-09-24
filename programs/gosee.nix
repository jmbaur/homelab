{ pkgs ? import <nixpkgs> { } }:
pkgs.buildGoModule {
  name = "gosee";
  src = builtins.fetchGit { url = "https://github.com/jmbaur/gosee.git"; };
  vendorSha256 = "07q9war08k1pqg5hz6pvc1pf1s9k70jgfwp7inxygh9p4k7lwnr1";
  runVend = true;
}
