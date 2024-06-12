{
  stdenv,
  fetchFromGitHub,
  kernel,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nat46";
  version = "unstable-2022-09-19";
  name = "${finalAttrs.pname}-${kernel.version}-${finalAttrs.version}";

  src = fetchFromGitHub {
    owner = "ayourtch";
    repo = "${finalAttrs.pname}";
    rev = "4c5beee236841724219598fabb1edc93d4f08ce5";
    hash = "sha256-ljEhWJ2h7S3hzA5bkq6yOwgaOxNBALXqJCkOLVqfjXc=";
  };
  sourceRoot = "${finalAttrs.src.name}/nat46/modules";

  patches = [ ./nat46.patch ];

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernel.makeFlags ++ [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KVER=${kernel.modDirVersion}"
    "KERNEL_MODLIB=$(out)/lib/modules/${kernel.modDirVersion}"
    "INCLUDEDIR=$(out)/include"
  ];
})
