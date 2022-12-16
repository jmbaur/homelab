{ lib, stdenv, coreboot-toolchain, git, fetchgit, ... }:
let
  toolchain-system =
    if
      stdenv.hostPlatform.system == "x86_64-linux" then "i386"
    else if
      stdenv.hostPlatform.system == "aarch64-linux" then "aarch64"
    else throw "unsupported system";

  toolchain = coreboot-toolchain.${toolchain-system}.override { withAda = false; };
in

{ boardName, configfile, prebuildPayloads ? [ ], ... }:
stdenv.mkDerivation {
  pname = "coreboot-${boardName}";
  inherit (toolchain) version;
  src = fetchgit {
    inherit (toolchain.src) url rev leaveDotGit;
    sha256 = "sha256-k4tTtvBOHZoXqNhQwOyCRsYxlPvSdE4xwd9NnMfvUzM=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ git ];
  configurePhase = ''
    ln -sv ${toolchain} util/crossgcc/xgcc
    cp ${configfile} .config
    chmod +w .config # TODO(jared): don't make .config writeable
    ${lib.concatMapStringsSep ";" (p: "ln -sv ${p} .") prebuildPayloads}
  '';
  buildPhase = ''
    patchShebangs util
    make -j $NIX_BUILD_CORES
  '';
  installPhase = ''
    mkdir -p  $out
    cp build/coreboot.rom $out/coreboot.rom
  '';
}
