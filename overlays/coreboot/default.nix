{ stdenv, pkgsBuildBuild, python3, fetchgit, ... }:
{ boardName, configfile, extraConfig ? "", extraCbfsCommands ? "", ... }:
let
  toolchain-system = builtins.getAttr stdenv.hostPlatform.linuxArch {
    "x86_64" = "i386";
    "arm64" = "aarch64";
    "arm" = "arm";
    "riscv" = "riscv";
    "powerpc" = "ppc64";
  };
  toolchain = pkgsBuildBuild.coreboot-toolchain.${toolchain-system}.override { withAda = false; };
in
stdenv.mkDerivation {
  pname = "coreboot-${boardName}";
  inherit (toolchain) version;
  src = fetchgit {
    inherit (toolchain.src) url rev;
    leaveDotGit = false;
    fetchSubmodules = true;
    sha256 = "sha256-QvQ87mPnETNZL3GbMHHBAOxJFvRDUzIlXSiuLG7wxEw=";
  };
  depsBuildBuild = [ pkgsBuildBuild.stdenv.cc ];
  nativeBuildInputs = [ python3 ];
  patches = [ ./memory-layout.patch ];
  postPatch = ''
    patchShebangs util
  '';
  inherit extraConfig;
  passAsFile = [ "extraConfig" ];
  configurePhase = ''
    runHook preConfigure
    cat ${configfile} > .config
    cat $extraConfigPath >> .config
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
