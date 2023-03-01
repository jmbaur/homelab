{ stdenv, fetchFromGitHub, qmk, ... }:
stdenv.mkDerivation {
  name = "kinesis-kint41-jmbaur";
  src = fetchFromGitHub {
    owner = "jmbaur";
    repo = "qmk_firmware";
    rev = "03f6834375c5880eb7e4ffb803f1dbff615e0c6f";
    sha256 = "sha256-lwe++uxV3eTmNJXh5mzbI6v683HmouZ1TRSuhK5Jbc0=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ qmk ];
  makeFlags = [ "kinesis/kint41:jmbaur" ];
  installPhase = ''
    mkdir -p $out
    cp .build/kinesis_kint41_jmbaur.hex $out
  '';
}
