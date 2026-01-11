{
  lib,
  stdenvNoCC,
  zig_0_15,
}:

let
  root = ../../..;
in
stdenvNoCC.mkDerivation (
  finalAttrs:
  let
    deps = stdenvNoCC.mkDerivation {
      pname = finalAttrs.pname + "-deps";
      inherit (finalAttrs) src version;
      depsBuildBuild = [ zig_0_15 ];
      buildCommand = ''
        export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
        runHook unpackPhase
        cd $sourceRoot
        zig build --fetch
        mv $ZIG_GLOBAL_CACHE_DIR/p $out
      '';
      outputHashAlgo = null;
      outputHashMode = "recursive";
      outputHash = "sha256-GcuXahLxAXtkALRfOhjVMQq84w8XJx/XYLN9LauF/VY=";
    };
  in
  {
    pname = "homelab-utils";
    version = "0.0.0";

    src = lib.fileset.toSource {
      inherit root;
      fileset = lib.fileset.unions [
        (root + /build.zig)
        (root + /build.zig.zon)
        (root + /src)
      ];
    };

    nativeBuildInputs = [ zig_0_15 ];

    strictDeps = true;
    doCheck = true;
    dontStrip = true;

    zigBuildFlags = [
      "-Dtarget=${stdenvNoCC.hostPlatform.qemuArch}-${stdenvNoCC.hostPlatform.parsed.kernel.name}"
    ];

    # TODO(jared): libsodium modifies downloaded contents at build time (this
    # should be fixed). In addition to that, it fails when
    # ZIG_GLOBAL_CACHE_DIR is set (that should also be checked).
    configurePhase = ''
      runHook preConfigure
      cp -r ${deps} $ZIG_GLOBAL_CACHE_DIR/p
      chmod u+w --recursive $ZIG_GLOBAL_CACHE_DIR/p
      runHook postConfigure
    '';
    passthru.deps = deps;
    meta.platforms = lib.platforms.linux;
  }
)
