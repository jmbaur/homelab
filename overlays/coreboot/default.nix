{ stdenv, buildPackages, python3, coreboot-toolchain, fetchgit, ... }:
let
  toolchain = coreboot-toolchain.override { withAda = false; };
in
{ boardName
, configfile
, extraConfig ? ""
, extraCbfsCommands ? ""
, ...
}:
stdenv.mkDerivation {
  pname = "coreboot-${boardName}";
  inherit (toolchain) version;
  src = fetchgit {
    inherit (toolchain.src) url rev;
    leaveDotGit = false;
    fetchSubmodules = true;
    sha256 = "sha256-hJ3Cp1OfMp8ZgRCzENUPPnoPTovKG4NiYabEpk3T2R0=";
  };
  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ python3 ];
  patches = [ ./increase-ramstage-size.patch ];
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
  makeFlags = [ "XGCCPATH=${toolchain}/bin/" ];
  preInstall = extraCbfsCommands;
  installPhase = ''
    runHook preInstall
    mkdir -p  $out
    cp build/coreboot.rom $out/coreboot.rom
    runHook postInstall
  '';
}
