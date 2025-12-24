{
  stdenvNoCC,
  zig_0_15,
}:

stdenvNoCC.mkDerivation {
  name = "nixos-kexec";
  nativeBuildInputs = [ zig_0_15 ];
  buildCommand = ''
    mkdir -p $out/bin

    export ZIG_GLOBAL_CACHE_DIR=$TEMPDIR
    zig test -j$NIX_BUILD_CORES ${./nixos-kexec.zig}
    zig build-exe \
      -j$NIX_BUILD_CORES \
      -femit-bin=$out/bin/nixos-kexec \
      -fstrip \
      -O ReleaseSafe \
      -target ${stdenvNoCC.hostPlatform.qemuArch}-${stdenvNoCC.hostPlatform.rust.platform.os} \
      ${./nixos-kexec.zig}
    rm -f $out/bin/*.o
  '';
}
