{
  applyPatches,
  fetchFromGitHub,
  replaceVars,
}:

applyPatches rec {
  src = fetchFromGitHub {
    owner = "MarvellEmbeddedProcessors";
    repo = "mv-ddr-marvell";
    rev = "4a3dc0909b64fac119d4ffa77840267b540b17ba";
    hash = "sha256-atsj0FCEkMLfnABsaJZGHKO0ZKad19jsKAkz39fIcFY=";
  };
  patches = [
    (replaceVars ./remove-impurity.patch {
      shortRev = builtins.substring 0 7 src.rev;
    })
  ];
}
