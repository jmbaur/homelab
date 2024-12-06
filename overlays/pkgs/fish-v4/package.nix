{
  cargo,
  cmake,
  fetchFromGitHub,
  gettext,
  pcre2,
  pkg-config,
  rustPlatform,
  rustc,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fish";
  version = "v4.0.0-alpha1-${builtins.substring 0 7 finalAttrs.src.rev}";

  src = fetchFromGitHub {
    owner = "fish-shell";
    repo = "fish-shell";
    rev = "210d687b2b2780b1862b7c2ed64cd4c0d84acbde";
    hash = "sha256-mnzA9i/Rt8QvqK0IAyGKVDhg1j4Chg22N1hqABoGmeQ=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src;
    hash = "sha256-jTVZKzX/Uy2RtyMbeQmatLLrOO+5S5jXrYKMGXNMcV4=";
  };

  env.FISH_BUILD_VERSION = finalAttrs.version;

  strictDeps = true;
  enableParallelBuilding = true;

  nativeBuildInputs = [
    pkg-config
    cargo
    cmake
    rustPlatform.cargoSetupHook
    rustc
  ];

  buildInputs = [
    pcre2
    gettext
  ];

  meta.mainProgram = "fish";
})
