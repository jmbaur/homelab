self: super: {
  zls = super.zls.overrideAttrs (old: {
    version = "master";
    src = super.fetchFromGitHub {
      owner = "zigtools";
      repo = "zls";
      rev = "12cda9b0310605d170b932ebb6005e44e41f4ee1";
      sha256 = "sha256-/HM0D8QQaDVUzT9qMVacDkKV43X4yVVORThkmrYL2pQ=";
      fetchSubmodules = true;
    };
  });
}
