{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "t14s-x1e80100-linux-firmware";
  version = "20241003";

  src = fetchFromGitHub {
    owner = "jollheef";
    repo = "linux-firmware-x1e78100-lenovo-thinkpad-t14s";
    rev = "e3ba8bb550b023b9f8501360f1d85d74d3de96b4";
    hash = "sha256-REkQpg+27to11VoDfAksvqzi5M7MDjAcAvR7P8cnRk0=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/firmware
    cp -r * $out/lib/firmware/
    runHook postInstall
  '';

  dontStrip = true;

  postFixup = ''
    find -L $out -type f -exec chmod 444 {} \;
  '';

  meta = {
    description = "Firmware files for ThinkPad T14s Gen 6";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
