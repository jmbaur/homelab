# TODO(jared): Fix cross-compilation and get dynamic linking working.

{ pkgsStatic }:
pkgsStatic.callPackage (
  {
    lib,
    libsodium,
    runCommand,
    stdenv,
    zig_0_14,
  }:
  runCommand "nix-key" { depsBuildBuild = [ zig_0_14 ]; } ''
    mkdir -p $out/bin

    export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
    args=(
      "-fno-lld"
      "-j$NIX_BUILD_CORES"
      "-target ${stdenv.hostPlatform.qemuArch}-linux"
      "--dynamic-linker ${stdenv.cc.libc}/lib/ld-linux*"
      "-I${lib.getDev stdenv.cc.libc}/include"
      "-I${lib.getDev libsodium}/include"
      "-L${lib.getLib libsodium}/lib"
      "-lc"
      "-lsodium"
    )
    zig test ''${args[@]} -j$NIX_BUILD_CORES ${./nix-key.zig}
    zig build-exe ''${args[@]} \
      -femit-bin=$out/bin/nix-key \
      -fstrip -O ReleaseSafe \
      ${./nix-key.zig}
    rm -f $out/bin/*.o
  ''
) { }
