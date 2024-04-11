{
  clang-tools,
  efm-langserver,
  fd,
  fswatch,
  ghc,
  git,
  go-tools,
  gofumpt,
  gopls,
  haskell-language-server,
  lib,
  lua-language-server,
  neovim-unwrapped,
  neovimUtils,
  nil,
  nixfmt-rfc-style,
  ormolu,
  ripgrep,
  ruff,
  rust-analyzer,
  rustfmt,
  shellcheck,
  shfmt,
  skim,
  taplo,
  texlive,
  tree-sitter,
  vimPlugins,
  vimUtils,
  wrapNeovimUnstable,
  writeText,
  zls,
  runCommand,
  supportAllLanguages ? false,
  languageSupport ? lib.genAttrs [
    "c"
    "go"
    "haskell"
    "latex"
    "lua"
    "nix"
    "python"
    "rust"
    "shell"
    "toml"
    "zig"
  ] (_: supportAllLanguages),
}:
let
  langSupportLua = writeText "lang-support.lua" (
    lib.concatLines (
      lib.mapAttrsToList (
        lang: supported: ''vim.g.lang_support_${lang} = ${lib.boolToString supported}''
      ) languageSupport
    )
  );

  jmbaur-config = vimUtils.buildVimPlugin {
    name = "jmbaur-nvim-config";
    src = runCommand "jmbaur-nvim-config-src" { inherit langSupportLua; } ''
      cp -r ${./settings} $out
      substituteInPlace $out/lua/init.lua --subst-var langSupportLua
    '';
  };

  config = neovimUtils.makeNeovimConfig {
    plugins =
      [ jmbaur-config ]
      ++ (
        with vimPlugins;
        # start
        [
          diffview-nvim
          efmls-configs-nvim
          gitsigns-nvim
          gosee-nvim
          iron-nvim
          mini-nvim
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
        ++ (map (plugin: {
          inherit plugin;
          optional = true;
        }) [ ])
      );
  };

  neovim = neovim-unwrapped.overrideAttrs (
    {
      patches ? [ ],
      ...
    }:
    {
      patches = patches ++ [
        # ./tmux-osc52.patch
      ];
    }
  );
in
wrapNeovimUnstable neovim (
  config
  // {
    vimAlias = true;
    # Disable wrapRc since it adds a `-u` flag to nvim, causing stuff like exrc
    # to not work OOTB.
    wrapRc = false;
    wrapperArgs =
      config.wrapperArgs
      ++ (
        let
          binPath = lib.makeBinPath (
            [
              efm-langserver
              fd # telescope
              fswatch # for faster LSP experience
              git # vim-fugitive
              ripgrep # telescope
              skim
              tree-sitter
            ]
            ++ (lib.optionals languageSupport.c [ clang-tools ])
            ++ (lib.optionals languageSupport.go [
              go-tools
              gofumpt
              gopls
            ])
            ++ (lib.optionals languageSupport.haskell [
              ghc
              haskell-language-server
              ormolu
            ])
            ++ (lib.optionals languageSupport.latex [
              (texlive.combine { inherit (texlive) scheme-minimal latexindent; })
            ])
            ++ (lib.optionals languageSupport.lua [ lua-language-server ])
            ++ (lib.optionals languageSupport.nix [
              nil
              nixfmt-rfc-style
            ])
            ++ (lib.optionals languageSupport.rust [
              rust-analyzer
              rustfmt
            ])
            ++ (lib.optionals languageSupport.shell [
              shellcheck
              shfmt
            ])
            ++ (lib.optionals languageSupport.toml [ taplo ])
            ++ (lib.optionals languageSupport.zig [ zls ])
            ++ (lib.optionals languageSupport.python [ ruff ])
          );
        in
        [
          "--prefix"
          "PATH"
          ":"
          binPath
        ]
      );
  }
)
