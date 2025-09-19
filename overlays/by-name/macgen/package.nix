{
  runCommand,
  stdenv,
  zig_0_15,
}:

runCommand "macgen" { depsBuildBuild = [ zig_0_15 ]; } ''
  mkdir -p $out/bin

  export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
  zig test -j$NIX_BUILD_CORES ${./macgen.zig}
  zig build-exe \
    -femit-bin=$out/bin/macgen \
    -fstrip \
    -O ReleaseSafe \
    -target ${stdenv.hostPlatform.qemuArch}-${stdenv.hostPlatform.rust.platform.os} \
    ${./macgen.zig}
  rm -f $out/bin/*.o
''
