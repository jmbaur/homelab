{ supportAllLanguages ? false
, languageSupport ? lib.genAttrs [ "c" "go" "haskell" "latex" "lua" "nix" "python" "rust" "shell" "toml" "zig" ] (_: supportAllLanguages)
, clang-tools
, efm-langserver
, fd
, fetchgit
, ghc
, git
, go-tools
, gofumpt
, gopls
, haskell-language-server
, lib
, lua-language-server
, neovim-unwrapped
, neovimUtils
, nil
, nixpkgs-fmt
, ormolu
, python3
, ripgrep
, ruff
, rust-analyzer
, rustfmt
, shellcheck
, shfmt
, skim
, taplo
, texlive
, tree-sitter
, vimPlugins
, vimUtils
, wrapNeovimUnstable
, zls
}:
let
  tree-sitter-just = tree-sitter.buildGrammar rec {
    language = "just";
    version = builtins.substring 0 7 src.rev;
    src = fetchgit {
      inherit (lib.importJSON ../tree-sitter-just-source.json) url rev hash;
    };
  };

  tree-sitter-just-plugin = vimUtils.buildVimPlugin {
    name = "tree-sitter-just";
    inherit (tree-sitter-just) src;
  };

  jmbaur-config = vimUtils.buildVimPlugin {
    name = "jmbaur-nvim-config";
    src = ./settings;
  };

  config = neovimUtils.makeNeovimConfig {
    plugins = with vimPlugins;
      # start
      [
        (nvim-treesitter.withPlugins (_: nvim-treesitter.allGrammars ++ [ tree-sitter-just ]))
        diffview-nvim
        efmls-configs-nvim
        gitsigns-nvim
        gosee-nvim
        jmbaur-config
        mini-nvim
        nvim-lspconfig
        nvim-surround
        nvim-treesitter-refactor
        nvim-treesitter-textobjects
        oil-nvim
        snippets-nvim
        telescope-nvim
        telescope-ui-select-nvim
        tree-sitter-just-plugin
        vim-dispatch
        vim-eunuch
        vim-flog
        vim-fugitive
        vim-gist
        vim-just
        vim-nix
        vim-repeat
        vim-rsi
      ]
      # opt
      ++ (map (plugin: { inherit plugin; optional = true; }) [ ]);
  };

  neovim = neovim-unwrapped.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ /*./tmux-osc52.patch*/ ];
  });
in
wrapNeovimUnstable neovim (config // {
  vimAlias = true;
  wrapperArgs = config.wrapperArgs ++ (
    let
      binPath = lib.makeBinPath ([ fd git ripgrep skim tree-sitter efm-langserver ]
        ++ (lib.optionals languageSupport.c [ clang-tools ])
        ++ (lib.optionals languageSupport.go [ go-tools gofumpt gopls ])
        ++ (lib.optionals languageSupport.haskell [ ghc haskell-language-server ormolu ])
        ++ (lib.optionals languageSupport.latex [ (texlive.combine { inherit (texlive) scheme-minimal latexindent; }) ])
        ++ (lib.optionals languageSupport.lua [ lua-language-server ])
        ++ (lib.optionals languageSupport.nix [ nil nixpkgs-fmt ])
        ++ (lib.optionals languageSupport.rust [ rust-analyzer rustfmt ])
        ++ (lib.optionals languageSupport.shell [ shellcheck shfmt ])
        ++ (lib.optionals languageSupport.toml [ taplo ])
        ++ (lib.optionals languageSupport.zig [ zls ])
        ++ (lib.optionals languageSupport.python [
        ruff
        (python3.withPackages (p: with p; [
          pylsp-mypy
          python-lsp-black
          python-lsp-server
        ]))
      ])
      );
    in
    [ "--prefix" "PATH" ":" binPath ]
  );
})
