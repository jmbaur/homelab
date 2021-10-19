{ pkgs ? import <nixpkgs> }:
pkgs.buildGoModule {
  name = "efm-langserver";
  src = pkgs.fetchFromGitHub {
    owner = "mattn";
    repo = "efm-langserver";
    rev = "d5f5b9aedaf654c158af9312a69ed717d5bf6bf5";
    sha256 = "096xh1j7dmm0jjww8zg2db8ffb4n9crb1pq1117z05k7g0p3mfi0";
  };
  vendorSha256 = "1d1zbzlvbiqy4y1409prkl9sslgzjxc602pqq3n9j07zg32v93v3";
  runVend = true;
}
