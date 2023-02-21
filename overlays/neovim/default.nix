{ supportAllLanguages ? false
, languageSupport ? lib.genAttrs [ "c" "go" "html" "latex" "lua" "markdown" "nix" "python" "rust" "shell" "toml" "typescript" "yaml" "zig" ] (_: supportAllLanguages)
, clang-tools
, deno
, fd
, git
, go-tools
, gofumpt
, gopls
, html-tidy
, lib
, lua-language-server
, neovim-unwrapped
, neovimUtils
, nil
, nixpkgs-fmt
, nodePackages
, python3
, ripgrep
, ruff
, rust-analyzer
, shellcheck
, shfmt
, skim
, taplo
, texlive
, tree-sitter
, vimPlugins
, wrapNeovimUnstable
, yamlfmt
, zls
, ...
}:
let
  config = neovimUtils.makeNeovimConfig {
    plugins = with vimPlugins;
      # start
      [
        editorconfig-nvim
        fzf-lua
        gosee-nvim
        jmbaur-settings
        mini-nvim
        null-ls-nvim
        nvim-colorizer-lua
        nvim-lspconfig
        nvim-surround
        nvim-treesitter-refactor
        nvim-treesitter-textobjects
        nvim-treesitter.withAllGrammars
        oil-nvim
        playground
        smartyank-nvim
        snippets-nvim
        vim-dispatch
        vim-eunuch
        vim-flog
        vim-fugitive
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
      binPath = lib.makeBinPath ([ fd git ripgrep skim tree-sitter ]
        ++ (lib.optionals languageSupport.c [ clang-tools ])
        ++ (lib.optionals languageSupport.go [ go-tools gofumpt gopls ])
        ++ (lib.optionals languageSupport.html [ html-tidy ])
        ++ (lib.optionals languageSupport.latex [ (texlive.combine { inherit (texlive) scheme-minimal latexindent; }) ])
        ++ (lib.optionals languageSupport.lua [ lua-language-server ])
        ++ (lib.optionals languageSupport.markdown [ deno ])
        ++ (lib.optionals languageSupport.nix [ nil nixpkgs-fmt ])
        ++ (lib.optionals languageSupport.rust [ rust-analyzer ])
        ++ (lib.optionals languageSupport.shell [ shellcheck shfmt ])
        ++ (lib.optionals languageSupport.toml [ taplo ])
        ++ (lib.optionals languageSupport.typescript [ deno nodePackages.typescript-language-server ])
        ++ (lib.optionals languageSupport.yaml [ yamlfmt ])
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
