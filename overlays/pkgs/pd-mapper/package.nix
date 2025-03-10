{
  stdenv,
  lib,
  fetchFromGitHub,
  pkg-config,
  qrtr,
  xz,
}:

stdenv.mkDerivation {
  pname = "pd-mapper";
  version = "unstable-2024-06-19";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "pd-mapper";
    rev = "e7c42e1522249593302a5b8920b9e7b42dc3f25e";
    sha256 = "sha256-gTUpltbY5439IEEvnxnt8WOFUgfpQUJWr5f+OB12W8A=";
  };

  postPatch = ''
    substituteInPlace pd-mapper.c --replace "/lib/firmware" "/run/current-system/firmware"
  '';

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    qrtr
    xz
  ];

  installFlags = [ "prefix=$(out)" ];

  meta = {
    mainProgram = "pd-mapper";
    description = "pd mapper";
    homepage = "https://github.com/linux-msm/pd-mapper";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
}
