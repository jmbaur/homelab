self: super:
let
  name = "c2esp";
  version = "27";
in
{
  c2esp = super.stdenv.mkDerivation {
    inherit name version;
    nativeBuildInputs = with super; [ cups cups-filters jbigkit zlib ];
    src = fetchurl {
      url = "mirror://sourceforge/cupsdriverkodak/${name}-${version}.tar.gz";
      sha256 = "sha256-8JX5y7U5zUi3XOxv4vhEugy4hmzl5DGK1MpboCJDltQ=";
    };
    # prevent ppdc not finding <font.defs>
    CUPS_DATADIR = "${super.cups}/share/cups";
    preConfigure = ''
      configureFlags="--with-cupsfilterdir=$out/lib/cups/filter"
    '';
    NIX_CFLAGS_COMPILE = [ "-include stdio.h" ];
    installPhase = ''
      mkdir -p $out/lib/cups/filter $out/lib/cups/ppd
      cp src/c2esp $out/lib/cups/filter/c2esp
      cp src/c2espC $out/lib/cups/filter/c2espC
      cp src/command2esp $out/lib/cups/filter/command2esp
      cp ppd/*.ppd $out/lib/cups/ppd/
    '';
  };
}
