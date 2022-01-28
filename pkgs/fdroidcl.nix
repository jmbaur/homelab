{ buildGoModule, fetchFromGitHub }:
buildGoModule {
  name = "fdroidcl";
  src = fetchFromGitHub {
    owner = "mvdan";
    repo = "fdroidcl";
    rev = "1bd0f39050540dec815e93c7e4b10c4f8a52ba89";
    sha256 = "13f2yqysbj5scd7swznjhzsf8jalfnzdv1p3ipzaqzz2snc6vbhc";
  };
  vendorSha256 = "sha256-uy+pfFX1GFRKYk/u1ALiQRzkv7vvqho0x+ahucLKE4U=";
}
