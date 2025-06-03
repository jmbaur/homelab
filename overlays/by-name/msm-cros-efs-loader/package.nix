{
  fetchFromGitLab,
  stdenvNoCC,
  lib,
  bash,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "msm-cros-efs-loader";
  version = lib.substring 0 7 finalAttrs.src.rev;

  src = fetchFromGitLab {
    domain = "gitlab.postmarketos.org";
    owner = "postmarketOS";
    repo = "msm-cros-efs-loader";
    rev = "161432c3c112226348d692ef6cac97eef999f0a9";
    hash = "sha256-HsqPdHF1SpmBISpRH9MGvmj248G22BG0bvhDKiAHJNI=";
  };

  dontConfigure = true;
  dontBuild = true;

  # used in fixupPhase to provide shell for patchShebangs
  buildInputs = [ bash ];

  installPhase = ''
    runHook preInstall

    install -Dm0755 msm-cros-efs-loader.sh $out/bin/msm-cros-efs-loader

    runHook postInstall
  '';

  meta.mainProgram = "msm-cros-efs-loader";
})
