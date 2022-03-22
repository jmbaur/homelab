final: prev: {
  fdroidcl = prev.callPackage ./fdroidcl.nix { };
  vimPlugins = prev.vimPlugins // {
    jmbaur-settings = prev.callPackage ./neovim-settings { };
  };
  p = prev.callPackage ./p.nix { };
  zf = prev.callPackage ./zf.nix { };
}
