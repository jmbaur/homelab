{ lib, stdenv, fetchgit, qmk, ... }:

let
  source = lib.importJSON ./qmk-source.json;
in
stdenv.mkDerivation {
  pname = "kinesis-kint41-jmbaur";
  version = "unstable-${builtins.substring 0 7 source.rev}";

  src = fetchgit {
    inherit (source)
      url hash fetchSubmodules fetchLFS deepClone leaveDotGit;
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
}

