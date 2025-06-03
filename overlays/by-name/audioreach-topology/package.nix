{
  alsa-utils,
  cmake,
  fetchFromGitHub,
  gnum4,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "audioreach-topology";
  version = "0-unstable-2025-03-19";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "audioreach-topology";
    rev = "04c5aebc660236625f18c9da2a1e1ee4afbf5e3a";
    hash = "sha256-BbyLV+1wDiGOtj6WEtTumJ2OGthjD1h4RkXD8lLJ/sw=";
  };

  nativeBuildInputs = [
    alsa-utils
    cmake
    gnum4
  ];

  installPhase = ''
    runHook preInstall

    find ./qcom -name '*.bin' -exec install -Dm0444 -t $out {} \;

    runHook postInstall
  '';
}
