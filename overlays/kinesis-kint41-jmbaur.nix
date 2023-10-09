{ stdenv, fetchFromGitHub, qmk, ... }:
stdenv.mkDerivation {
  name = "kinesis-kint41-jmbaur";
  src = fetchFromGitHub {
    owner = "jmbaur";
    repo = "qmk_firmware";
    rev = "bdbbc5d7d551f8b2ed0252575ae6ca5bfc436d1e";
    hash = "sha256-EPpfv9Td16MD2VNkzvygfTbBgVga8kDgrKLab8exGks=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ qmk ];
  makeFlags = [ "kinesis/kint41:jmbaur" ];
  installPhase = ''
    runHook preInstall

    install -D --target-directory=$out .build/kinesis_kint41_jmbaur.hex

    runHook postInstall
  '';
}
