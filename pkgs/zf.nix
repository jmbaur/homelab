{ stdenvNoCC
, fetchFromGitHub
, zig
, lib
}:
stdenvNoCC.mkDerivation rec {
  pname = "zf";
  version = "readline";
  src = fetchFromGitHub {
    owner = "jmbaur";
    repo = "zf";
    rev = version;
    sha256 = "sha256-B6VIQUIJnhIUJk/YteVEdTZZOqBLSd2poD5PMYl014E=";
  };
  preBuild = ''
    export HOME=$TMPDIR
  '';
  installPhase = ''
    ${zig}/bin/zig build --prefix $out install
  '';
}
