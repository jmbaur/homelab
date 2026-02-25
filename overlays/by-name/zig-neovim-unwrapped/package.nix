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
      outputHash = "sha256-LYsz94rZAeGB5M2zEwm3QXHfPC43ms3v2j6sfU7R1yU=";
    };
  in
  {
    pname = "neovim-unwrapped";
    version = "0.12.0-dev";

    src = fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "44429b4d96503d13f0663806d84d14209f33b7c8";
      hash = "sha256-TnH43TuyKQs23btpQmLKkKExxx6UhMj7GcdBCqJjnvU=";
    };

    __structuredAttrs = true;
    strictDeps = true;

    postConfigure = ''
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
