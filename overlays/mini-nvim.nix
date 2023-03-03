{ vimUtils, fetchFromGitHub, ... }:
vimUtils.buildVimPluginFrom2Nix rec {
  pname = "mini.nvim";
  version = builtins.substring 0 7 src.rev;
  src = fetchFromGitHub {
    owner = "echasnovski";
    repo = "mini.nvim";
    rev = "c16a18124da94fd6d35669a2208b78da0fdd18e2";
    sha256 = "sha256-lBY7OjUpH+kI+a2GWTMev+RiKCn7J9jkd9XIW3jLTmg=";
  };
}
