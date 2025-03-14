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
    hash = "sha256-GW1S4e1Wuz4gRSJWduYbu0G4Lq9SUuFhR6SpZnA8cuo=";
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
