{ stdenv, buildPackages, python3, coreboot-toolchain, fetchgit, ... }:
{ boardName, configfile, extraConfig ? "", extraCbfsCommands ? "", ... }:
stdenv.mkDerivation {
  pname = "coreboot-${boardName}";
  inherit (coreboot-toolchain) version;
  src = fetchgit {
    inherit (coreboot-toolchain.src) url rev;
    leaveDotGit = false;
    fetchSubmodules = true;
    sha256 = "sha256-hJ3Cp1OfMp8ZgRCzENUPPnoPTovKG4NiYabEpk3T2R0=";
  };
  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ python3 ];
  patches = [ ./memory-layout.patch ];
  postPatch = ''
    patchShebangs util
  '';
  configurePhase = ''
    runHook preConfigure
    cp --no-preserve=mode ${configfile} .config
    cat >>.config <<EOF
    ${extraConfig}
    EOF
    make oldconfig
    runHook postConfigure
  '';
  makeFlags = [ "XGCCPATH=${coreboot-toolchain}/bin/" ];
  preInstall = extraCbfsCommands;
  installPhase = ''
    runHook preInstall
    mkdir -p  $out
    cp build/coreboot.rom $out/coreboot.rom
    runHook postInstall
  '';
}
