{ rustPlatform, fetchFromGitHub, ... }:
rustPlatform.buildRustPackage rec {
  pname = "cicada";
  version = "0.9.36";

  src = fetchFromGitHub {
    owner = "mitnk";
    repo = "cicada";
    rev = "v${version}";
    sha256 = "sha256-KEl9jSdH13usE+dC9fUvb6VbayB/XBo9VVMzd+hR/lg=";
  };

  cargoSha256 = "sha256-NKOD64iN+EwzVXNA2KNsOxwNYx5B/YyGdn5vvcYH3t4=";

  doCheck = false;
}
