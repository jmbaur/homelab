{
  runCommand,
  stdenv,
  zig_0_15,
}:

runCommand "networkd-dhcpv6-client-prefix"
  {
    depsBuildBuild = [ zig_0_15 ];
    meta.mainProgram = "networkd-dhcpv6-client-prefix";
  }
  ''
    mkdir -p $out/bin

    export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
    zig test -j$NIX_BUILD_CORES ${./networkd-dhcpv6-client-prefix.zig}
    zig build-exe \
      -j$NIX_BUILD_CORES \
      -femit-bin=$out/bin/networkd-dhcpv6-client-prefix \
      -fstrip \
      -O ReleaseSafe \
      -target ${stdenv.hostPlatform.qemuArch}-${stdenv.hostPlatform.rust.platform.os} \
      ${./networkd-dhcpv6-client-prefix.zig}
    rm -f $out/bin/*.o
  ''
