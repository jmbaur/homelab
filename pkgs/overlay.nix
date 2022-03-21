final: prev: {
  fdroidcl = prev.callPackage ./fdroidcl.nix { };
  gopls = prev.gopls.override { buildGoModule = prev.buildGo118Module; };
  vimPlugins = prev.vimPlugins // {
    jmbaur-settings = prev.callPackage ./neovim-settings { };
  };
  p = prev.callPackage ./p.nix { };
  zf = prev.callPackage ./zf.nix { };
}
