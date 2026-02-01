{
  fetchFromGitHub,
  pkgsBuildBuild,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qebspil";
  version = "1";

  src = fetchFromGitHub {
    owner = "stephan-gh";
    repo = "qebspil";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-kWUXzeYWNxGgmjt/p9yozrWc5ouUs0XXBRfiFMlu+QQ=";
  };

  makeFlags = [ "CROSS_COMPILE=${stdenv.cc.targetPrefix}" ];

  depsBuildBuild = [ pkgsBuildBuild.stdenv.cc ];

  installPhase = ''
    runHook preInstall
    install -Dt $out out/*.efi
    runHook postInstall
  '';
})
