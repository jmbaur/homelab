{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "orangepi-firmware";
  version = "unstable-2024-10-09";

  src = fetchFromGitHub {
    owner = "orangepi-xunlong";
    repo = "firmware";
    rev = "75ea6fc5f3c454861b39b33823cb6876f3eca598";
    hash = "sha256-X+n0voO3HRtPPAQsajGPIN9LOfDKBxF+8l9wFwGAFSQ=";
  };

  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/firmware
    cp -r . $out/lib/firmware

    runHook postInstall
  '';
}
