{
  fetchFromGitHub,
  lib,
  pkg-config,
  ninja,
  meson,
  qrtr,
  stdenv,
  zstd,
  systemdLibs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tqftpserv";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "tqftpserv";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Djw2rx1FXYYPXs6Htq7jWcgeXFvfCUoeidKtYUvTqZU=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    qrtr
    systemdLibs
    zstd
  ];

  installFlags = [ "prefix=$(out)" ];

  meta = {
    description = "Trivial File Transfer Protocol server over AF_QIPCRTR";
    homepage = "https://github.com/linux-msm/tqftpserv";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.aarch64;
  };
})
