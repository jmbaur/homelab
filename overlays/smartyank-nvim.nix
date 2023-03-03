{ vimUtils, fetchFromGitHub, ... }:
vimUtils.buildVimPluginFrom2Nix rec {
  pname = "smartyank.nvim";
  version = builtins.substring 0 7 src.rev;
  src = fetchFromGitHub {
    owner = "ibhagwan";
    repo = "smartyank.nvim";
    rev = "7e3905578f646503525b2f7018b8afd17861018c";
    sha256 = "sha256-/3gTxovokK7loljVPJHu6PB2nX4j6sK2ydaPay9Dl6Y=";
  };
}
