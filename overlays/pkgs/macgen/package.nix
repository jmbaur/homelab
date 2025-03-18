{
  runCommand,
  stdenv,
  zig_0_14,
}:

runCommand "macgen" { depsBuildBuild = [ zig_0_14 ]; } ''
  mkdir -p $out/bin

  export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
  zig test -j$NIX_BUILD_CORES ${./macgen.zig}
  zig build-exe \
    -femit-bin=$out/bin/macgen \
    -fstrip \
    -O ReleaseSafe \
    -target ${stdenv.hostPlatform.qemuArch}-linux \
    ${./macgen.zig}
  rm -f $out/bin/*.o
''
