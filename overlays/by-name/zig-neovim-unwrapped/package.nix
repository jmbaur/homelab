{
  fetchFromGitHub,
  lib,
  nukeReferences,
  patchelfUnstable,
  pkgsBuildBuild,
  stdenv,
  zig_0_15,
}:

assert
  # cross-compilation currently broken
  stdenv.buildPlatform == stdenv.hostPlatform
  &&
    # static musl isn't capable of dlopen(), needed for treesitter to work
    !stdenv.hostPlatform.isStatic;
stdenv.mkDerivation (
  finalAttrs:
  let
    deps = zig_0_15.fetchDeps {
      fetchAll = true;
      inherit (finalAttrs) pname version src;
      hash = "sha256-x5zyufIJ/wNv//W0Zeg9xMvVdGxUh6ovmWvL9dvwIQU=";
    };
  in
  {
    pname = "neovim-unwrapped";
    version = "0.13.0-dev";

    src = fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "843a7223e77d63be496e6bcfbe1fca89b7010266";
      hash = "sha256-x/cL+5wuEbfHoqzkah6ux6XnY6/NEPkmLiTuWE4+Dqk=";
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

    postConfigure = ''
      ln -s ${deps} $ZIG_GLOBAL_CACHE_DIR/p
    '';

    inherit (pkgsBuildBuild.neovim-unwrapped) meta lua;

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
