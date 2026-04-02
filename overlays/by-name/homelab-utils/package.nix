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
    deps = zig_0_15.fetchDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-GcuXahLxAXtkALRfOhjVMQq84w8XJx/XYLN9LauF/VY=";
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

    __structuredAttrs = true;
    doCheck = true;
    dontPatchELF = true;
    dontStrip = true;
    strictDeps = true;

    zigBuildFlags = [
      "-Dtarget=${stdenvNoCC.hostPlatform.qemuArch}-${
        {
          darwin = "macos";
          linux = "linux";
        }
        .${stdenvNoCC.hostPlatform.parsed.kernel.name}
      }"
    ];

    # TODO(jared): libsodium modifies downloaded contents at build time (this
    # should be fixed).
    postConfigure = ''
      cp -r ${deps} $ZIG_GLOBAL_CACHE_DIR/p
      chmod u+w --recursive $ZIG_GLOBAL_CACHE_DIR/p
    '';
    passthru.deps = deps;
    meta.platforms = lib.platforms.all;
  }
)
