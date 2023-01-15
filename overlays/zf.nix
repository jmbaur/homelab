{ stdenvNoCC, fetchFromGitHub, zig }:
stdenvNoCC.mkDerivation rec {
  pname = "zf";
  version = "0.6.0"; # 0.6.0 and up require zig 0.10.0
  src = fetchFromGitHub {
    owner = "natecraddock";
    repo = "zf";
    rev = version;
    sha256 = "sha256-zmlNvChcRXYCo6BtjSG+G1Re9hPZVFW1EKyj4/CIdmg=";
  };
  HOME = "/tmp";
  installPhase = ''
    ${zig}/bin/zig build -Drelease-fast=true --prefix $out install
  '';
}
