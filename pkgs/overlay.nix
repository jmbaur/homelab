final: prev: {
  fdroidcl = prev.callPackage ./fdroidcl.nix { };
  vimPlugins = prev.vimPlugins // {
    jmbaur-settings = prev.callPackage ./neovim-settings { };
    zenbones-nvim = prev.vimUtils.buildVimPlugin rec {
      name = "zenbones.nvim";
      # Source contains a Makefile for code-generation. Prevent nixpkgs from
      # running `make` by giving an explicit build phase.
      buildPhase = ":";
      src = prev.fetchFromGitHub {
        owner = "mcchrish";
        repo = name;
        rev = "1e0b792efd4cee41c8005d6b61a6e1f91a630c6b";
        sha256 = "0qxym2ybrj7jaa6l5f7kf9zxjgb5mh5flc8h8bxafp9h2naxxnrg";
      };
    };
    telescope-zf-native = prev.vimUtils.buildVimPlugin rec {
      name = "telescope-zf-native.nvim";
      src = prev.fetchFromGitHub {
        owner = "natecraddock";
        repo = name;
        rev = "76ae732e4af79298cf3582ec98234ada9e466b58";
        sha256 = "sha256-acV3sXcVohjpOd9M2mf7EJ7jqGI+zj0BH9l0DJa14ak=";
      };
    };
  };
  p = prev.callPackage ./p.nix { };
  zf = prev.callPackage ./zf.nix { };
  opentaxsolver = prev.callPackage ./opentaxsolver.nix { };
}
