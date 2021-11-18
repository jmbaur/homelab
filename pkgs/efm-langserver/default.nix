{ pkgs ? import <nixpkgs> }:
with pkgs;
buildGoModule {
  name = "efm-langserver";
  src = fetchFromGitHub {
    owner = "mattn";
    repo = "efm-langserver";
    rev = "899ab62a08e8eff1b1f0f89d899a5832c8cd361a";
    sha256 = "sha256-+Q3vSifPiE9PyxJnoapJ1CBKUioTHExwBbWJgWD1iNI=";
  };
  vendorSha256 = "sha256-Y4+0xXj/AJnswPgKYFiX/1GtE535JkCCJx7HtelfP7Q=";
  runVend = true;
}
