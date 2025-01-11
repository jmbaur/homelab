{
  fetchpatch,
  lib,
  pkg-config,
  pkgsBuildBuild,
  sqlite,
  stdenv,
}:

let
  zigLibc =
    {
      "glibc" = "gnu";
      "musl" = "musl";
    }
    .${stdenv.hostPlatform.libc} or "none";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "local-overlay-fixup-db";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./build.zig
      ./build.zig.zon
      ./src
    ];
  };

  nativeBuildInputs = [
    pkg-config
    (pkgsBuildBuild.zig_0_13.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        (fetchpatch {
          url = "https://github.com/ziglang/zig/commit/bcf40a1406f1b19372ce13bbd8d3b1a1d2d0f678.patch";
          hash = "sha256-a+veRN1WTNltmg78/qZUIQAlVADy1N/3kcDCMqnliU4=";
        })
      ];
    })).hook
  ];
  buildInputs = [ sqlite ];

  zigBuildFlags = [
    "-Dtarget=${stdenv.hostPlatform.qemuArch}-${stdenv.hostPlatform.parsed.kernel.name}-${zigLibc}"
    "-Ddynamic-linker=${stdenv.cc.bintools.dynamicLinker}"
  ];

  doCheck = true;

  meta = {
    description = "Program to fixup the upper Nix DB for local-overlay on A/B updated systems";
    mainProgram = "local-overlay-fixup-db";
  };
})
