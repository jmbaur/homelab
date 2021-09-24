{ pkgs ? import <nixpkgs> { } }:
pkgs.buildGoModule {
  name = "fdroidcl";
  src = builtins.fetchGit { url = "https://github.com/mvdan/fdroidcl.git"; };
  vendorSha256 = "11q0gy3wfjaqyfj015yw3wfz2j1bsq6gchjhjs6fxfjmb77ikwjb";
  runVend = true;
}
