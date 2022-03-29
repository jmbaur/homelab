{ stdenvNoCC
, fetchFromGitHub
, zig
}:
stdenvNoCC.mkDerivation rec {
  pname = "zf";
  version = "6a717d19f661b2ed31cedacac3708c35ba152242";
  src = fetchFromGitHub {
    owner = "natecraddock";
    repo = "zf";
    rev = version;
    sha256 = "1rxh2sgmzpv1inpjsxak30mmma2j1w3ya2q4kcjy8sxyz7v7c4ka";
  };
  preBuild = ''
    export HOME=$TMPDIR
  '';
  installPhase = ''
    ${zig}/bin/zig build --prefix $out install
  '';
}
