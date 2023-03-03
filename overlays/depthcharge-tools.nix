{ python3, fetchFromGitHub, vboot_reference, makeWrapper, lib, bzip2, dtc, file, gzip, lz4, lzma, lzop, ubootTools, xz, zstd, ... }:
let
  binPath = lib.makeBinPath [
    bzip2
    dtc
    file
    gzip
    lz4
    lzma
    lzop
    ubootTools
    vboot_reference
    xz
    zstd
  ];
in
python3.pkgs.buildPythonApplication rec {
  pname = "depthcharge-tools";
  version = "0.6.1";
  src = fetchFromGitHub {
    owner = "alpernebbi";
    repo = "depthcharge-tools";
    rev = "v${version}";
    sha256 = "sha256-kHf3R1sKTqb3KDf3qA65bIKJcF7QbjOo7Lduv2VEZq4=";
  };
  prePatch = ''
    substituteInPlace depthcharge_tools/config.ini \
      --replace /usr/share/vboot ${vboot_reference}/share/vboot \
  '';
  propagatedBuildInputs = with python3.pkgs; [ setuptools ];
  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    wrapProgram $out/bin/mkdepthcharge \
      --prefix PATH : ${binPath}
  '';
}
