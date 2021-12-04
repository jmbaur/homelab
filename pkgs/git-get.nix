{ callPackage, fetchFromGitHub }:
callPackage
  (fetchFromGitHub {
    owner = "jmbaur";
    repo = "git-get";
    rev = "7c62f18ef84b03a665c97c41ef14967b93e1686d";
    sha256 = "sha256-PlSuaSszC0Ws+Ql8Hc3AXNTEPC6qcSu6YwxxVzdeoQQ=";
  })
{ }
