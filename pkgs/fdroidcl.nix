{ buildGoModule, fetchFromGitHub }:
buildGoModule {
  name = "fdroidcl";
  src = fetchFromGitHub {
    owner = "mvdan";
    repo = "fdroidcl";
    rev = "1bd0f39050540dec815e93c7e4b10c4f8a52ba89";
    sha256 = "13f2yqysbj5scd7swznjhzsf8jalfnzdv1p3ipzaqzz2snc6vbhc";
  };
  vendorSha256 = "11q0gy3wfjaqyfj015yw3wfz2j1bsq6gchjhjs6fxfjmb77ikwjb";
  runVend = true;
}
