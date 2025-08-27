{
  lib,
  libsodium,
  stdenv,
  zig_0_15,
  writeText,
}:

stdenv.mkDerivation {
  name = "nix-key";
  depsBuildBuild = [ zig_0_15 ];
  passthru.broken = !stdenv.hostPlatform.isGnu;
  buildCommand = ''
    mkdir -p $out/bin

    export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
    args=(
      "-j$NIX_BUILD_CORES"
      "-target ${stdenv.hostPlatform.qemuArch}-linux-gnu"
      "--libc ${writeText "libc.txt" ''
        include_dir=${lib.getDev stdenv.cc.libc}/include
        sys_include_dir=${lib.getDev stdenv.cc.libc}/include
        crt_dir=${stdenv.cc.libc}/lib
        msvc_lib_dir=
        kernel32_lib_dir=
        gcc_dir=
      ''}"
      "--dynamic-linker $(cat $NIX_CC/nix-support/dynamic-linker)"
      "-I${lib.getDev libsodium}/include"
      "-L${lib.getLib libsodium}/lib"
      "-lc"
      "-lsodium"
      "-feach-lib-rpath"
    )
    zig test ''${args[@]} -j$NIX_BUILD_CORES ${./nix-key.zig}
    zig build-exe ''${args[@]} \
      -femit-bin=$out/bin/nix-key \
      -fstrip -O ReleaseSafe \
      ${./nix-key.zig}
    rm -f $out/bin/*.o
  '';
}
