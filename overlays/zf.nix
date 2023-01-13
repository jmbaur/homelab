{ stdenvNoCC, fetchFromGitHub, zig }:
stdenvNoCC.mkDerivation rec {
  pname = "zf";
  version = "0.5"; # 0.6.0 and up require zig 0.10.0
  src = fetchFromGitHub {
    owner = "natecraddock";
    repo = "zf";
    rev = version;
    sha256 = "sha256-df7fK3aYoMP4x0XWscYb9xrHl0tl8L9GcgCDQ6lTTnc=";
  };
  HOME = "/tmp";
  installPhase = ''
    ${zig}/bin/zig build -Drelease-fast=true --prefix $out install
  '';
}
