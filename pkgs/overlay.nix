final: prev: {
  fdroidcl = prev.callPackage ./fdroidcl.nix { };
  c2esp = prev.callPackage ./c2esp.nix {};
  vimPlugins = prev.vimPlugins // {
    lsp = prev.vimUtils.buildVimPlugin rec {
      name = "lsp";
      src = prev.fetchFromGitHub {
        owner = "yegappan";
        repo = name;
        rev = "a025c97dcfcfe399622449a54897ca9593810d3d";
        sha256 = "0kvnyaxkm8036hw6pm0n4fxjl0520gpsp654snndr34dn4pkzddp";
      };
    };
  };
  p = prev.callPackage ./p.nix { };
  zf = prev.callPackage ./zf.nix { };
}
