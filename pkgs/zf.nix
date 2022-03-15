{ stdenvNoCC
, fetchFromGitHub
, zig
}:
stdenvNoCC.mkDerivation rec {
  pname = "zf";
  version = "0.4";
  src = fetchFromGitHub {
    owner = "natecraddock";
    repo = "zf";
    rev = version;
    sha256 = "sha256-A9yTh0/xzpQ9PcmIx85Q7JHpJSdoeDOry/OKkiPj7cM=";
  };
  preBuild = ''
    export HOME=$TMPDIR
  '';
  installPhase = ''
    ${zig}/bin/zig build --prefix $out install
  '';
}
