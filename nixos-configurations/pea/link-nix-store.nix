{ pkgsBuildBuild, stdenv }:
stdenv.mkDerivation (finalAttrs: {
  pname = "link-nix-store";
  version = "0.1.0";
  doBuild = false;
  doCheck = false;
  src = ./.;
  depsBuildBuild = [ pkgsBuildBuild.zig_0_11 ];
  installPhase = ''
    export ZIG_GLOBAL_CACHE_DIR=/tmp
    zig test ${finalAttrs.pname}.zig
    zig build-exe -target ${stdenv.hostPlatform.qemuArch}-linux -fstrip -O ReleaseSmall ${finalAttrs.pname}.zig
    install -D --target-directory=$out/bin link-nix-store
  '';
  meta.mainProgram = finalAttrs.pname;
})
