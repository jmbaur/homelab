{
  runCommand,
  stdenv,
  zig_0_14,
}:

runCommand "homelab-backup-recv" { depsBuildBuild = [ zig_0_14 ]; } ''
  mkdir -p $out/bin

  export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
  zig test -j$NIX_BUILD_CORES ${./homelab-backup-recv.zig}
  zig build-exe \
    -j$NIX_BUILD_CORES \
    -femit-bin=$out/bin/homelab-backup-recv \
    -fstrip \
    -O ReleaseSafe \
    -target ${stdenv.hostPlatform.qemuArch}-linux \
    ${./homelab-backup-recv.zig}
''
