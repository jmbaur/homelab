{ fetchFromGitHub
, python3
, wrapGAppsHook
, stdenv
, gobject-introspection
, gtk3
}:

let
  pythonEnv = python3.withPackages (p: with p; [ pygobject3 ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "labwc-gtktheme";
  version = "unstable-${builtins.substring 0 7 finalAttrs.src.rev}";

  src = fetchFromGitHub {
    owner = "jmbaur";
    repo = finalAttrs.pname;
    rev = "bad25e85dabaea468922ffb0e15b5d5ae4030860";
    hash = "sha256-Wt2/Wcq93lTaY53fXRKAagK3NfP3A6j37ZE5aROKXxY=";
  };
  nativeBuildInputs = [ gtk3 gobject-introspection wrapGAppsHook ];
  buildInputs = [ pythonEnv ];

  doBuild = false;
  installPhase = ''
    runHook preInstall
    patchShebangs .
    install -D --target-directory=$out/bin labwc-gtktheme.py
    runHook postInstall
  '';

  meta.mainProgram = "labwc-gtktheme.py";
})
