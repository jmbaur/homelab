{ stdenv
, fetchurl
, autoPatchelfHook
, cairo
, freetype
, glib
, gtk2-x11
, pango
}:
stdenv.mkDerivation rec {
  pname = "OpenTaxSolver2021";
  version = "19.07";
  src = fetchurl {
    url = "mirror://sourceforge/project/opentaxsolver/OTS_2021/v${version}_linux/OpenTaxSolver2021_${version}_linux64.tgz";
    sha256 = "sha256-5tX4equ1+ryVG09E7r7tTZ7mRbwv26XEVR9YGNEIDk0=";
  };
  name = "OpenTaxSolver";
  nativeBuildInputs = [ autoPatchelfHook cairo freetype glib gtk2-x11 pango ];
  installPhase = ''
    mkdir -p $out/bin
    cp -r bin $out/bin
    cp Run_taxsolve_GUI $out/bin
  '';
}
