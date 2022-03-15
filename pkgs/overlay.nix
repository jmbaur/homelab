final: prev: {
  kitty-themes = prev.kitty-themes.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "kovidgoyal";
      repo = "kitty-themes";
      rev = "36e208df34b2ab7c21bae709e63486f84ac6d735";
      sha256 = "14pmcjkl4d68gi6jv29cq07nvlr6jjjw1cws2lzalcai5k1qg356";
    };
  });
  fdroidcl = prev.callPackage ./fdroidcl.nix { };
  gopls = prev.gopls.override { buildGoModule = prev.buildGo118Module; };
  vimPlugins = prev.vimPlugins // {
    jmbaur-settings = prev.callPackage ./neovim-settings { };
  };
  p = prev.callPackage ./p.nix { };
  zf = prev.callPackage ./zf.nix { };
}
