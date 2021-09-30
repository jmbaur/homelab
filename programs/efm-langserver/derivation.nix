{ pkgs ? import <nixpkgs> }:
pkgs.buildGoModule {
  name = "efm-langserver";
  src = builtins.fetchTarball "https://github.com/mattn/efm-langserver/archive/master.tar.gz";
  vendorSha256 = "1d1zbzlvbiqy4y1409prkl9sslgzjxc602pqq3n9j07zg32v93v3";
  runVend = true;
}
