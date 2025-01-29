{
  lib,
  stdenv,
  fetchFromGitHub,
  udev,
  qrtr,
  qmic,
}:

stdenv.mkDerivation {
  pname = "rmtfs";
  version = "2024-03-18";

  buildInputs = [
    udev
    qrtr
    qmic
  ];

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "rmtfs";
    rev = "33e1e40615efc59b17a515afe857c51b8b8c1ad1";
    hash = "sha256-AxFuDmfLTcnnwm+nezwLc8yaHcX+pFkX5qSIO38T/BM=";
  };

  installFlags = [ "prefix=$(out)" ];

  meta = {
    description = "Qualcomm Remote Filesystem Service";
    homepage = "https://github.com/linux-msm/rmtfs";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.aarch64;
  };
}
