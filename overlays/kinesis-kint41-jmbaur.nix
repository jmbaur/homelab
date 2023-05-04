{ stdenv, fetchFromGitHub, qmk, ... }:
stdenv.mkDerivation {
  name = "kinesis-kint41-jmbaur";
  src = fetchFromGitHub {
    owner = "jmbaur";
    repo = "qmk_firmware";
    rev = "14315d41079c08eb8b4bd3299bb4babf0b70e2c8";
    sha256 = "sha256-AAwPLYSEGFum7920E6d/12VByPiH+dS2kF6IjVeGQ24=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ qmk ];
  makeFlags = [ "kinesis/kint41:jmbaur" ];
  installPhase = ''
    mkdir -p $out
    cp .build/kinesis_kint41_jmbaur.hex $out
  '';
}
