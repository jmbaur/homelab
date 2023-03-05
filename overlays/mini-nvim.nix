{ vimUtils, fetchFromGitHub, ... }:
vimUtils.buildVimPluginFrom2Nix rec {
  pname = "mini.nvim";
  version = builtins.substring 0 7 src.rev;
  src = fetchFromGitHub {
    owner = "echasnovski";
    repo = "mini.nvim";
    rev = "0.7.024da94fd6d35669a2208b78da0fdd18e2";
    sha256 = "";
  };
}
