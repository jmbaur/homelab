final: prev: {
  fdroidcl = prev.callPackage ./fdroidcl.nix { };
  c2esp = prev.callPackage ./c2esp.nix {};
  vimPlugins = prev.vimPlugins // {
    jmbaur-settings = prev.callPackage ./neovim-settings { };
    lsp = prev.vimUtils.buildVimPlugin rec {
      name = "lsp";
      src = prev.fetchFromGitHub {
        owner = "yegappan";
        repo = name;
        rev = "a025c97dcfcfe399622449a54897ca9593810d3d";
        sha256 = "0kvnyaxkm8036hw6pm0n4fxjl0520gpsp654snndr34dn4pkzddp";
      };
    };
    fileselect = prev.vimUtils.buildVimPlugin rec {
      name = "fileselect";
      src = prev.fetchFromGitHub {
        owner = "yegappan";
        repo = name;
        rev = "ab294c9739c5118fd554bb4ff135f33bab182272";
        sha256 = "01j3h4wzkm62788r14mh7155gi9zf9mwrb4s5a7yp7myi0w8bcns";
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
}
