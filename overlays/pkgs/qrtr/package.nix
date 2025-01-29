{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  ninja,
}:

stdenv.mkDerivation {
  pname = "qrtr";
  version = "unstable-2024-05-21";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "qrtr";
    rev = "daf7f4cc326a5036dcce2bd7deaf2c32841b0336";
    hash = "sha256-OGx5fxxtrNN9EJJxxH4MTDRFGsyu4LNo+ks46zbJqF0=";
  };

  nativeBuildInputs = [
    meson
    ninja
  ];

  mesonFlags = [ "-Dsystemd-service=disabled" ];

  installFlags = [ "prefix=$(out)" ];

  meta = {
    description = "QMI IDL compiler";
    homepage = "https://github.com/linux-msm/qrtr";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.aarch64;
  };
}
