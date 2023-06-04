{ stdenv, fetchFromGitHub, qmk, ... }:
stdenv.mkDerivation {
  name = "kinesis-kint41-jmbaur";
  src = fetchFromGitHub {
    owner = "jmbaur";
    repo = "qmk_firmware";
    rev = "c0aace4f4ad6cdd272e4d9857be85be67a506cd4";
    sha256 = "sha256-OhrR1X8KpQK5ySEwOozcreZJW+pw+1yeKQJ/dzMRuRc=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ qmk ];
  makeFlags = [ "kinesis/kint41:jmbaur" ];
  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp .build/kinesis_kint41_jmbaur.hex $out

    runHook postInstall
  '';
}
