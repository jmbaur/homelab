{ buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "fdroidcl";
  version = "0.7.0";
  src = fetchFromGitHub {
    owner = "mvdan";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-tqhs3b/DHfnGOm9qcM56NSzt1GJflJfbemkp7+nXbug=";
  };
  patches = [ ./fdroidcl-go-mod.patch ];
  vendorSha256 = "sha256-BWbwhHjfmMjiRurrZfW/YgIzJUH/hn+7qonD0BcTLxs=";
  ldflags = [ "-s" "-w" ];
  doCheck = false; # checks try to reach the network
}
