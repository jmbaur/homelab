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
      outputHash = "sha256-9BsVZCy+8KLKanc3QRFWubPMc7VvOSvvhJdWHGwERyA=";
    };
  in
  {
    pname = "neovim-unwrapped";
    version = "0.12.0-dev";

    src = fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "d9d8c660fd5559d928c8870a21970a375674e310";
      hash = "sha256-2c4H+5f0qhsp13Vx8pbsGiSRTHBJIfQaRAAUSHGEpgo=";
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
