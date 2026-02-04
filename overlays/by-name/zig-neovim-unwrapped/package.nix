{
  fetchFromGitHub,
  neovim-unwrapped,
  stdenvNoCC,
  zig_0_15,
}:

stdenvNoCC.mkDerivation (
  finalAttrs:
  let
    deps = stdenvNoCC.mkDerivation {
      pname = finalAttrs.pname + "-deps";
      inherit (finalAttrs) version src nativeBuildInputs;
      buildCommand = ''
        export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
        runHook unpackPhase
        cd $sourceRoot
        zig build --fetch=all
        mv $ZIG_GLOBAL_CACHE_DIR/p $out
      '';
      outputHashAlgo = null;
      outputHashMode = "recursive";
      outputHash = "sha256-/auHXoPhbxzjx2Jw7AtARYkFr0sC5YuivB9LbkWZxSQ=";
    };
  in
  {
    pname = "neovim-unwrapped";
    version = "0.12.0-dev";
    src = fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "a2b92a5efbb4159d15311f015bb270f80de42e3a";
      hash = "sha256-MvlZ5vv0st2vXyqWjYQX0KIzcmFiwxPkmDH0BnYYBhI=";
    };

    __structuredAttrs = true;
    strictDeps = true;

    postHook = ''
      ln -s ${deps} $ZIG_GLOBAL_CACHE_DIR/p
    '';

    nativeBuildInputs = [ zig_0_15 ];

    inherit (neovim-unwrapped) meta lua;

    # Not performed by the zig install, but needed by pkgs.wrapNeovimUnstable
    postInstall = ''
      install -Dm0644 ${neovim-unwrapped}/share/applications/nvim.desktop $out/share/applications/nvim.desktop
    '';
  }
)
