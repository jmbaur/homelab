{ stdenvNoCC, fetchFromGitHub, zig }:
stdenvNoCC.mkDerivation rec {
  pname = "zf";
  version = "0.6.0";
  src = fetchFromGitHub {
    owner = "natecraddock";
    repo = "zf";
    rev = version;
    sha256 = "sha256-zmlNvChcRXYCo6BtjSG+G1Re9hPZVFW1EKyj4/CIdmg=";
  };
  preBuild = ''
    export HOME=$TMPDIR
  '';
  installPhase = ''
    ${zig}/bin/zig build --prefix $out install
  '';
}
