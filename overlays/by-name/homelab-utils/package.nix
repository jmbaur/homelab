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
      outputHash = "sha256-efsa+bt/eliKgc6dO9KTjaukIrr+YmxpwQO43zIA+mA=";
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
    dontInstall = true;
    doCheck = true;
    dontStrip = true;

    zigBuildFlags = [
      "--color off"
      "--release=safe"
      "-Dtarget=${stdenvNoCC.hostPlatform.qemuArch}-${stdenvNoCC.hostPlatform.parsed.kernel.name}"
    ];

    # TODO(jared): libsodium modifies downloaded contents at build time (this
    # should be fixed). In addition to that, it fails when
    # ZIG_GLOBAL_CACHE_DIR is set (that should also be checked).
    configurePhase = ''
      runHook preConfigure
      export HOME=$TEMPDIR
      mkdir -p $HOME/.cache/zig
      cp -r ${deps} $HOME/.cache/zig/p
      chmod u+w --recursive $HOME/.cache/zig
      runHook postConfigure
    '';
    buildPhase = ''
      runHook preBuild
      zig build install --prefix $out ''${zigBuildFlags[@]}
      runHook postBuild
    '';
    checkPhase = ''
      runHook preCheck
      zig build test ''${zigBuildFlags[@]}
      runHook postCheck
    '';
    passthru.deps = deps;
    meta.platforms = lib.platforms.linux;
  }
)
