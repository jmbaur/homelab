{
  fetchFromGitHub,
  qmk,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jmbaur-qmk-keyboards";
  version = "0.34.4";

  src = fetchFromGitHub {
    owner = "qmk";
    repo = "qmk_firmware";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-c9H3cWyj0l00/pBHdNslO/b8rKWILa2c6RqynAvKlPw=";
  };

  nativeBuildInputs = [ qmk ];

  enableParallelBuilding = true;

  dontFixup = true;

  patches = [
    ./kinesis-kint41-jmbaur.patch
    ./zsa-moonlander-jmbaur.patch
  ];

  makeFlags = [
    "kinesis/kint41:jmbaur"
    "zsa/moonlander:jmbaur"
  ];

  installPhase = ''
    runHook preInstall
    install -D --target-directory=$out .build/*.hex .build/*.bin
    runHook postInstall
  '';
})
