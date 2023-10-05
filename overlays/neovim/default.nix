{ supportAllLanguages ? false
, languageSupport ? lib.genAttrs [ "c" "go" "haskell" "latex" "lua" "nix" "python" "rust" "shell" "toml" "zig" ] (_: supportAllLanguages)
, clang-tools
, efm-langserver
, fd
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
, wrapNeovimUnstable
, zls
, ...
}:
let
  config = neovimUtils.makeNeovimConfig {
    plugins = with vimPlugins;
      # start
      [
        efmls-configs-nvim
        gitsigns-nvim
        gosee-nvim
        jmbaur-settings
        mini-nvim
        nvim-colorizer-lua
        nvim-lspconfig
        nvim-surround
        nvim-treesitter-refactor
        nvim-treesitter-textobjects
        nvim-treesitter.withAllGrammars
        playground
        smartyank-nvim
        snippets-nvim
        telescope-frecency-nvim
        telescope-nvim
        telescope-ui-select-nvim
        toggleterm-nvim
        vim-dispatch
        vim-eunuch
        vim-flog
        vim-fugitive
        vim-gist
        vim-nix
        vim-repeat
        vim-rsi
      ]
      # opt
      ++ (map (plugin: { inherit plugin; optional = true; }) [ ]);
  };
in
wrapNeovimUnstable neovim-unwrapped (config // {
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
