{
  fetchFromGitHub,
  lib,
  pkg-config,
  qmic,
  qrtr,
  stdenv,
  systemdLibs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rmtfs";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "rmtfs";
    rev = "v${finalAttrs.version}";
    hash = "sha256-iyTIPuzZofs2n0aoiA/06edDXWoZE3/NY1vsy6KuUiw=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    qmic
    qrtr
    systemdLibs
  ];

  installFlags = [ "prefix=$(out)" ];

  meta = {
    description = "Qualcomm Remote Filesystem Service";
    homepage = "https://github.com/linux-msm/rmtfs";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.aarch64;
  };
})
