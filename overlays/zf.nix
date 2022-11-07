{ stdenvNoCC, fetchFromGitHub, zig }:
stdenvNoCC.mkDerivation rec {
  pname = "zf";
  version = "0.5";
  src = fetchFromGitHub {
    owner = "natecraddock";
    repo = "zf";
    rev = version;
    sha256 = "0xsfafll70q0f93bzw359fbwf6pp3g3b3mj5qzwc784qfqmxzzkm";
  };
  preBuild = ''
    export HOME=$TMPDIR
  '';
  installPhase = ''
    ${zig}/bin/zig build --prefix $out install
  '';
}
