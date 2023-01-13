{ vimUtils, fetchFromGitHub, ... }:
vimUtils.buildVimPlugin rec {
  pname = "oil-nvim";
  version = builtins.substring 0 7 src.rev;
  src = fetchFromGitHub {
    owner = "stevearc";
    repo = "oil.nvim";
    rev = "abfc455f62dac385b0fc816f37c64dffead0bcf3";
    hash = "sha256-oA220nzaBlFnJ0s23oabIW3XV1tWml5kBuBkTImOPjM=";
  };
}
