{
  runCommand,
  stdenv,
  zig_0_14,
}:

runCommand "macgen" { depsBuildBuild = [ zig_0_14 ]; } ''
  mkdir -p $out/bin

  ZIG_GLOBAL_CACHE_DIR=$TEMPDIR zig build-exe \
    -j$NIX_BUILD_CORES \
    -femit-bin=$out/bin/macgen \
    -fstrip \
    -O ReleaseSafe \
    -target ${stdenv.hostPlatform.qemuArch}-linux \
    ${./macgen.zig}
''
