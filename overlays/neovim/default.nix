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
  languageSupport_c ? supportAllLanguages,
  languageSupport_go ? supportAllLanguages,
  languageSupport_haskell ? supportAllLanguages,
  languageSupport_latex ? supportAllLanguages,
  languageSupport_lua ? supportAllLanguages,
  languageSupport_nix ? supportAllLanguages,
  languageSupport_python ? supportAllLanguages,
  languageSupport_rust ? supportAllLanguages,
  languageSupport_shell ? supportAllLanguages,
  languageSupport_toml ? supportAllLanguages,
  languageSupport_zig ? supportAllLanguages,
}@args:
let
  langSupportLua = writeText "lang-support.lua" (
    lib.concatLines (
      lib.mapAttrsToList (
        arg: supported:
        ''vim.g.lang_support_${lib.removePrefix "languageSupport_" arg} = ${lib.boolToString supported}''
      ) (lib.filterAttrs (arg: _: lib.hasPrefix "languageSupport_" arg) args)
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
in
wrapNeovimUnstable neovim-unwrapped (
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
            ++ (lib.optionals languageSupport_c [ clang-tools ])
            ++ (lib.optionals languageSupport_go [
              go-tools
              gofumpt
              gopls
            ])
            ++ (lib.optionals languageSupport_haskell [
              ghc
              haskell-language-server
              ormolu
            ])
            ++ (lib.optionals languageSupport_latex [
              (texlive.combine { inherit (texlive) scheme-minimal latexindent; })
            ])
            ++ (lib.optionals languageSupport_lua [ lua-language-server ])
            ++ (lib.optionals languageSupport_nix [
              nil
              nixfmt-rfc-style
            ])
            ++ (lib.optionals languageSupport_rust [
              rust-analyzer
              rustfmt
            ])
            ++ (lib.optionals languageSupport_shell [
              shellcheck
              shfmt
            ])
            ++ (lib.optionals languageSupport_toml [ taplo ])
            ++ (lib.optionals languageSupport_zig [ zls ])
            ++ (lib.optionals languageSupport_python [ ruff ])
          );
        in
        [
          # Append shell path with tools so that whatever we have in our
          # environment has precedence.
          "--suffix"
          "PATH"
          ":"
          binPath
        ]
      );
  }
)
