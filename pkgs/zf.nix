{ stdenvNoCC
, fetchFromGitHub
, zigUnstable
}:
stdenvNoCC.mkDerivation rec {
  pname = "zf";
  version = "0.0.1";
  src = fetchFromGitHub {
    owner = "natecraddock";
    repo = "zf";
    rev = version;
    sha256 = "sha256-qcgJfTD6XrrXKoFY6dJ0y0IZnvLRNZIzT4zGhDiJ++A=";
  };
  preBuild = ''
    export HOME=$TMPDIR
  '';
  installPhase = ''
    ${zigUnstable}/bin/zig build --prefix $out install
  '';
}
