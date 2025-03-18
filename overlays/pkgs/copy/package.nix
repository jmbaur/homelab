{
  runCommand,
  stdenv,
  zig_0_14,
}:

runCommand "copy" { depsBuildBuild = [ zig_0_14 ]; } ''
  mkdir -p $out/bin

  export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
  zig test -j$NIX_BUILD_CORES ${./copy.zig}
  zig build-exe \
    -j$NIX_BUILD_CORES \
    -femit-bin=$out/bin/copy \
    -fstrip \
    -O ReleaseSafe \
    -target ${stdenv.hostPlatform.qemuArch}-linux \
    ${./copy.zig}
  rm -f $out/bin/*.o
''
