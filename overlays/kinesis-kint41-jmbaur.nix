{ stdenv, fetchFromGitHub, qmk, ... }:
stdenv.mkDerivation {
  name = "kinesis-kint41-jmbaur";
  src = fetchFromGitHub {
    owner = "jmbaur";
    repo = "qmk_firmware";
    rev = "ade74160c9d59013c6c35f15e50c021abca207bd";
    sha256 = "sha256-vjfVTXuTORaj8K/UXjPRh638SkkgibTvvuj9ajVwjRo=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ qmk ];
  makeFlags = [ "kinesis/kint41:jmbaur" ];
  installPhase = ''
    mkdir -p $out
    cp .build/kinesis_kint41_jmbaur.hex $out
  '';
}
