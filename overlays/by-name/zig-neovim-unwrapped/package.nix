{
  fetchFromGitHub,
  lib,
  neovim-unwrapped,
  nukeReferences,
  patchelfUnstable,
  pkgsBuildBuild,
  stdenv,
  stdenvNoCC,
  zig_0_15,
}:

let
  # cross-compilation currently broken
  canCross = false;
in
assert
  stdenv.buildPlatform == stdenv.hostPlatform
  &&
    # static musl isn't capable of dlopen(), needed for treesitter to work
    !stdenv.hostPlatform.isStatic;
stdenv.mkDerivation (
  finalAttrs:
  let
    deps = stdenvNoCC.mkDerivation {
      pname = finalAttrs.pname + "-deps";
      inherit (finalAttrs) src version;
      nativeBuildInputs = [ zig_0_15 ];
      buildCommand = ''
        export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
        runHook unpackPhase
        cd $sourceRoot
        zig build --fetch=all
        mv $ZIG_GLOBAL_CACHE_DIR/p $out
      '';
      outputHashAlgo = null;
      outputHashMode = "recursive";
      outputHash = "sha256-fuHlJAJTvSh4XAwm06Ax37P6w/aAMlibApxzThia3gs=";
    };
  in
  {
    pname = "neovim-unwrapped";
    version = "0.12.0-dev";

    src = fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "2f07bd0c1f2fe8602f272f391ecea6f777788bb6";
      hash = "sha256-FPc8NZKyfM9PMtm11nHPa1j/xc8HapeWWWJdQRDrdf8=";
    };

    __structuredAttrs = true;
    strictDeps = true;

    nativeBuildInputs = [
      nukeReferences
      patchelfUnstable
      zig_0_15
    ];

    # Prevent zig from being in the runtime closure
    disallowedReferences = [ zig_0_15 ];

    zigBuildFlags = lib.optionals canCross [
      "-Dtarget=${stdenv.hostPlatform.qemuArch}-${
        {
          darwin = "macos";
          linux = "linux";
        }
        .${stdenv.hostPlatform.parsed.kernel.name}
      }-gnu"
    ];

    postConfigure = ''
      ln -s ${deps} $ZIG_GLOBAL_CACHE_DIR/p
    '';

    inherit (neovim-unwrapped) meta lua;

    # Not performed by the zig install, but needed by pkgs.wrapNeovimUnstable
    postInstall = ''
      install -Dm0644 ${pkgsBuildBuild.neovim-unwrapped}/share/applications/nvim.desktop $out/share/applications/nvim.desktop
    '';

    # Ensure we have the required runtime dependencies, zig builds don't add rpath
    postFixup = ''
      find $out/bin $out/share/nvim/runtime/parser -type f | while read i; do
        nuke-refs -e $out -e ${lib.getLib stdenv.cc.libc} $i
        patchelf $i --add-rpath ${lib.getLib stdenv.cc.libc}/lib # for libc and friends
      done
    '';
  }
)
