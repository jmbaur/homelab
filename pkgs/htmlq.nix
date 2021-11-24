{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "htmlq";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "mgdm";
    repo = pname;
    rev = "2fccf67ef6a8dd43ba4e99f460a2b28a2781eb19";
    sha256 = "0w96bifl2k2vqndxgfay6pdha83z335ri8hh4g7hl5yvqrv3wg55";
  };

  cargoSha256 = "0cqbrs7c90k1zxmk3wwq5965vrvgzwwi9gxzvh8lsvinph1i5sld";

  meta = with lib; {
    description = "Like jq, but for HTML";
    homepage = "https://github.com/mgdm/htmlq";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ jmbaur ];
    mainProgram = "htmlq";
  };
}
