{
  runCommand,
  stdenv,
  zig_0_15,
}:

runCommand "homelab-garage-door"
  {
    depsBuildBuild = [ zig_0_15 ];
    meta.mainProgram = "homelab-garage-door";
  }
  ''
    mkdir -p $out/bin

    export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
    zig test -lc -j$NIX_BUILD_CORES ${./homelab-garage-door.zig}
    zig build-exe \
      -lc \
      -femit-bin=$out/bin/homelab-garage-door \
      -fstrip \
      -O ReleaseSafe \
      -target ${stdenv.hostPlatform.qemuArch}-linux \
      ${./homelab-garage-door.zig}
    rm -f $out/bin/*.o
  ''
