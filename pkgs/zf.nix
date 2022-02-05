{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "zf";
  version = "0.0.1";
  src = fetchFromGitHub {
    owner = "natecraddock";
    repo = "zf";
    rev = version;
    sha256 = "1ngcmd0qs55pfna9f12g473niy9y1gpj5xk58l9im8c2g66fp0nb";
  };
  preBuild = ''
    export HOME=$TMPDIR
  '';
  installPhase = ''
    ${pkgs.zig}/bin/zig version
    ${pkgs.zig}/bin/zig build --prefix $out install
  '';
}
