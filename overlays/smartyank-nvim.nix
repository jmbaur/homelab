{ vimUtils, fetchFromGitHub, ... }:
vimUtils.buildVimPlugin rec {
  pname = "smartyank-nvim";
  version = builtins.substring 0 7 src.rev;
  src = fetchFromGitHub {
    owner = "ibhagwan";
    repo = "smartyank.nvim";
    rev = "cd191d9629d620ccc608e6b4e60f3541264d0323";
    hash = "sha256-mAmdj+CMp5gxyJAioQA54l7XhYF2xSeFgm/v2LlModc=";
  };
}
