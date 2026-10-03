{
  edk2,
  lib,
  nasm,
  pkgsBuildHost,
  python3,
  util-linux,
}:

edk2.mkDerivation "MdeModulePkg/MdeModulePkg.dsc" (finalAttrs: {
  pname = "edk2-capsule-app";
  inherit (edk2) version;

  nativeBuildInputs = [
    nasm
    python3
    util-linux
  ];

  env.PYTHON_COMMAND = "${lib.getBin pkgsBuildHost.python3}/bin/python3";

  # Only build CapsuleApp, not all of MdeModulePkg
  buildFlags = [ "-m MdeModulePkg/Application/CapsuleApp/CapsuleApp.inf" ];

  # We only have a .efi file in $out which shouldn't be patched or stripped
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -D -m0644 Build/MdeModule/RELEASE_*/*/CapsuleApp.efi $out/CapsuleApp.efi
    runHook postInstall
  '';

  passthru.efi = "${finalAttrs.finalPackage}/CapsuleApp.efi";

  meta = {
    description = "UEFI application for applying firmware update capsules";
    homepage = "https://github.com/tianocore/edk2";
    license = lib.licenses.bsd2;
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
})
