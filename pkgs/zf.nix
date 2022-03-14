{ stdenvNoCC
, fetchFromGitHub
, zig
, lib
}:
stdenvNoCC.mkDerivation rec {
  pname = "zf";
  version = "master";
  src = fetchFromGitHub {
    owner = "natecraddock";
    repo = "zf";
    rev = version;
    sha256 = "13d96v9yni29qxb4kfcqxy9awy8c8yp7gnsjls8ndlhsq1hnz9l2";
  };
  preBuild = ''
    export HOME=$TMPDIR
  '';
  installPhase = ''
    ${zig}/bin/zig build --prefix $out install
  '';
}
