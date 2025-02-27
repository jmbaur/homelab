{
  fetchFromGitHub,
  lib,
  meson,
  ninja,
  pkg-config,
  stdenv,
  systemdLibs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qrtr";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "qrtr";
    rev = "v${finalAttrs.version}";
    hash = "sha256-cPd7bd+S2uVILrFF797FwumPWBOJFDI4NvtoZ9HiWKM=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [ systemdLibs ];

  installFlags = [ "prefix=$(out)" ];

  meta = {
    description = "QMI IDL compiler";
    homepage = "https://github.com/linux-msm/qrtr";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.aarch64;
  };
})
