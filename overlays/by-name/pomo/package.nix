{
  runCommand,
  stdenv,
  zig_0_15,
}:

runCommand "pomo" { depsBuildBuild = [ zig_0_15 ]; } ''
  mkdir -p $out/bin

  export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
  zig test -j$NIX_BUILD_CORES ${./pomo.zig}
  zig build-exe \
    -j$NIX_BUILD_CORES \
    -femit-bin=$out/bin/pomo \
    -fstrip \
    -O ReleaseSafe \
    -target ${stdenv.hostPlatform.qemuArch}-linux \
    ${./pomo.zig}
  rm -f $out/bin/*.o
''
