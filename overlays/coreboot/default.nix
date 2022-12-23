{ stdenv, buildPackages, python3, git, coreboot-toolchain, fetchgit, ... }:
let
  toolchain = buildPackages.coreboot-toolchain;
in
{ boardName, configfile, extraConfig ? "", ... }:
stdenv.mkDerivation {
  pname = "coreboot-${boardName}";
  inherit (coreboot-toolchain) version;
  src = fetchgit {
    inherit (toolchain.src) url rev leaveDotGit;
    sha256 = "sha256-cYfCtGicB6340/T61QKcMJEXXC/etD4BxTsoLdz29mw=";
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
