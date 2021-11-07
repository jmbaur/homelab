# Modified from https://github.com/zigtools/zls/blob/70ce776d00530149406f91310bea3ca8ca734d39/default.nix
{ zig
, pkgs ? import <nixpkgs> { }
, system ? builtins.currentSystem
}:

pkgs.stdenvNoCC.mkDerivation {
  name = "zls";
  version = "master";
  src = pkgs.fetchgit {
    url = "https://github.com/zigtools/zls";
    rev = "12cda9b0310605d170b932ebb6005e44e41f4ee1";
    sha256 = "sha256-/HM0D8QQaDVUzT9qMVacDkKV43X4yVVORThkmrYL2pQ=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ zig ];
  dontConfigure = true;
  dontInstall = true;
  buildPhase = ''
    mkdir -p $out
    zig build install -Drelease-safe=true -Ddata_version=master --prefix $out
  '';
  XDG_CACHE_HOME = ".cache";
}

