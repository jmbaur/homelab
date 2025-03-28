{
  stdenv,
  zig_0_14,
}:

stdenv.mkDerivation {
  name = "zbar";
  depsBuildBuild = [ zig_0_14 ];
  passthru.broken = !stdenv.hostPlatform.isGnu;
  buildCommand = ''
    mkdir -p $out/bin

    export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
    args=(
      "-j$NIX_BUILD_CORES"
      "-target ${stdenv.hostPlatform.qemuArch}-linux-gnu"
      "--dynamic-linker $(cat $NIX_CC/nix-support/dynamic-linker)"
      "-lc"
      "-feach-lib-rpath"
    )
    zig test ''${args[@]} -j$NIX_BUILD_CORES ${./zbar.zig}
    zig build-exe ''${args[@]} \
      -femit-bin=$out/bin/zbar \
      -fstrip -O ReleaseSafe \
      ${./zbar.zig}
    rm -f $out/bin/*.o
  '';
}
