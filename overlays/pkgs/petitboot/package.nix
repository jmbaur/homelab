{
  autoconf,
  autoreconfHook,
  bison,
  elfutils,
  fetchFromGitHub,
  flex,
  libtool,
  lvm2,
  pkg-config,
  stdenv,
  systemdLibs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "petitboot";
  version = "1.15";

  src = fetchFromGitHub {
    owner = "open-power";
    repo = "petitboot";
    tag = "v${finalAttrs.version}";
    hash = "sha256-C/afmQGQt3DKyYd3oFNLSZAu3wGWh0E1nrYJ6klbd/s=";
  };

  postPatch = ''
    patchShebangs version.sh
  '';

  depsBuildBuild = [ pkg-config ];
  nativeBuildInputs = [
    autoconf
    autoreconfHook
    bison
    elfutils
    flex
    libtool
    lvm2
    systemdLibs
  ];
})
