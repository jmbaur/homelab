{ rustPlatform, fetchFromGitHub, ... }:
rustPlatform.buildRustPackage rec {
  pname = "cicada";
  version = "0.9.35";

  src = fetchFromGitHub {
    owner = "mitnk";
    repo = "cicada";
    rev = "v${version}";
    sha256 = "sha256-HzZGuM9zB/msjG0nMuIJ+nvWc1twiB7q1tsAjV857Sc=";
  };

  cargoSha256 = "sha256-bDbQVusWPlq9Mu6rXXOFjUFrYttREHEceZRi7FwdBtE=";

  doCheck = false;
}
