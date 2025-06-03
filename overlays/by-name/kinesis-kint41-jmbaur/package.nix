{
  fetchFromGitHub,
  qmk,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kinesis-kint41-jmbaur";
  version = "0.28.0";

  src = fetchFromGitHub {
    owner = "qmk";
    repo = "qmk_firmware";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-ThFBLA1YlRmSVkOV3NW1YWF5NCsbWJRLfHQYIejiYGA=";
  };

  nativeBuildInputs = [ qmk ];

  enableParallelBuilding = true;

  patches = [ ./kinesis-kint41-jmbaur.patch ];

  makeFlags = [ "kinesis/kint41:jmbaur" ];

  installPhase = ''
    runHook preInstall
    install -D --target-directory=$out .build/kinesis_kint41_jmbaur.hex
    runHook postInstall
  '';
})
