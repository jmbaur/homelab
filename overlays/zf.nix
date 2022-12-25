{ stdenvNoCC, fetchFromGitHub, zig }:
stdenvNoCC.mkDerivation rec {
  pname = "zf";
  src = fetchFromGitHub {
    owner = "natecraddock";
    repo = "zf";
    rev = version;
  };
  preBuild = ''
    export HOME=$TMPDIR
  '';
  installPhase = ''
    ${zig}/bin/zig build -Drelease-fast=true --prefix $out install
  '';
}
