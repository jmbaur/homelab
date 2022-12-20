{ stdenv, buildPackages, python3, git, coreboot-toolchain, fetchgit, ... }:
let
  toolchain-system =
    if
      stdenv.hostPlatform.system == "x86_64-linux" then "i386"
    else if
      stdenv.hostPlatform.system == "aarch64-linux" then "aarch64"
    else throw "unsupported system";

  toolchain = buildPackages.coreboot-toolchain.${toolchain-system}.override { withAda = false; };
in
{ boardName, configfile, extraConfig ? "", ... }:
stdenv.mkDerivation {
  pname = "coreboot-${boardName}";
  inherit (toolchain) version;
  src = fetchgit {
    inherit (toolchain.src) url rev leaveDotGit;
    sha256 = "sha256-k4tTtvBOHZoXqNhQwOyCRsYxlPvSdE4xwd9NnMfvUzM=";
    fetchSubmodules = true;
  };
  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ python3 git ];
  postPatch = ''
    patchShebangs util
  '';
  configurePhase = ''
    cp --no-preserve=mode ${configfile} .config
    cat >>.config <<EOF
    ${extraConfig}
    EOF
    make oldconfig
  '';
  makeFlags = [ "XGCCPATH=${toolchain}/bin/" ];
  installPhase = ''
    mkdir -p  $out
    cp build/coreboot.rom $out/coreboot.rom
  '';
}
