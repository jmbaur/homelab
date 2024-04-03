{ clang-tools
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
, nixfmt-rfc-style
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
, supportAllLanguages ? false
, languageSupport ? lib.genAttrs
    [ "c" "go" "haskell" "latex" "lua" "nix" "python" "rust" "shell" "toml" "zig" ]
    (_: supportAllLanguages)
}:
let
  jmbaur-config = vimUtils.buildVimPlugin {
    name = "jmbaur-nvim-config";
    src = ./settings;
  };

  config = neovimUtils.makeNeovimConfig {
    plugins = [ jmbaur-config ] ++ (with vimPlugins;
      # start
      [
        diffview-nvim
        efmls-configs-nvim
        gitsigns-nvim
        gosee-nvim
        iron-nvim
        mini-nvim
        nvim-gdb
        nvim-lspconfig
        nvim-treesitter-context
        nvim-treesitter-refactor
        nvim-treesitter-textobjects
        nvim-treesitter.withAllGrammars
        oil-nvim
        snippets-nvim
        telescope-nvim
        telescope-ui-select-nvim
        telescope-zf-native-nvim
        vim-dispatch
        vim-eunuch
        vim-flog
        vim-fugitive
        vim-gist
        vim-nix
        vim-repeat
        vim-rhubarb
        vim-rsi
        zen-mode-nvim
      ]
      # opt
      ++ (map (plugin: { inherit plugin; optional = true; }) [ ]));
  };

  neovim = neovim-unwrapped.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ [ /*./tmux-osc52.patch*/ ];
  });
in
wrapNeovimUnstable neovim (config // {
  vimAlias = true;
  luaRcContent = lib.concatLines (lib.mapAttrsToList
    (lang: supported:
      ''vim.g.lang_support_${lang} = ${lib.boolToString supported}'')
    languageSupport);
  wrapperArgs = config.wrapperArgs ++ (
    let
      binPath = lib.makeBinPath ([ fd git ripgrep skim tree-sitter efm-langserver ]
        ++ (lib.optionals languageSupport.c [ clang-tools ])
        ++ (lib.optionals languageSupport.go [ go-tools gofumpt gopls ])
        ++ (lib.optionals languageSupport.haskell [ ghc haskell-language-server ormolu ])
        ++ (lib.optionals languageSupport.latex [ (texlive.combine { inherit (texlive) scheme-minimal latexindent; }) ])
        ++ (lib.optionals languageSupport.lua [ lua-language-server ])
        ++ (lib.optionals languageSupport.nix [ nil nixfmt-rfc-style ])
        ++ (lib.optionals languageSupport.rust [ rust-analyzer rustfmt ])
        ++ (lib.optionals languageSupport.shell [ shellcheck shfmt ])
        ++ (lib.optionals languageSupport.toml [ taplo ])
        ++ (lib.optionals languageSupport.zig [ zls ])
        ++ (lib.optionals languageSupport.python [ ruff (python3.withPackages (p: with p; [ pylsp-mypy python-lsp-black python-lsp-server ])) ])
      );
    in
    [ "--prefix" "PATH" ":" binPath ]
  );
})
