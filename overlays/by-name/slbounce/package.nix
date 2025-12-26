{
  stdenv,
  fetchFromGitHub,
  # gnu-efi,
  dtc,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "slbounce";
  version = "5";

  src = fetchFromGitHub {
    owner = "TravMurav";
    repo = "slbounce";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-X1lGJ+OYNcPORq3qqf1TLcuYa82sHAecXkUyiarnEp4=";
  };

  makeFlags = [ "CROSS_COMPILE=${stdenv.cc.targetPrefix}" ];

  nativeBuildInputs = [ dtc ];

  installPhase = ''
    runHook preInstall
    install -Dt $out out/*.efi
    runHook postInstall
  '';
})
