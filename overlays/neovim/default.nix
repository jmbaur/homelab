{
  clang-tools,
  efm-langserver,
  fd,
  fswatch,
  fzf,
  ghc,
  git,
  git-extras,
  go-tools,
  gofumpt,
  gopls,
  haskell-language-server,
  inotify-tools,
  lib,
  lua-language-server,
  neovim-unwrapped,
  neovimUtils,
  nil,
  nixfmt-rfc-style,
  ormolu,
  pyright,
  ripgrep,
  ruff,
  runCommand,
  rust-analyzer,
  rustc,
  rustfmt,
  shellcheck,
  shfmt,
  taplo,
  texlive,
  tree-sitter,
  vimPlugins,
  vimUtils,
  wrapNeovimUnstable,
  writeText,
  xdg-utils,
  zls,
  supportAllLanguages ? false,
  cSupport ? supportAllLanguages,
  goSupport ? supportAllLanguages,
  haskellSupport ? supportAllLanguages,
  latexSupport ? supportAllLanguages,
  luaSupport ? supportAllLanguages,
  nixSupport ? supportAllLanguages,
  pythonSupport ? supportAllLanguages,
  rustSupport ? supportAllLanguages,
  shellSupport ? supportAllLanguages,
  tomlSupport ? supportAllLanguages,
  zigSupport ? supportAllLanguages,
}:
let
  langSupportLua = writeText "lang-support.lua" (
    lib.concatLines (
      lib.mapAttrsToList
        (
          lang: supported:
          ''vim.g.lang_support_${lib.removeSuffix "Support" lang} = ${lib.boolToString supported}''
        )
        {
          inherit
            cSupport
            goSupport
            haskellSupport
            latexSupport
            luaSupport
            nixSupport
            pythonSupport
            rustSupport
            shellSupport
            tomlSupport
            zigSupport
            ;
        }
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
        (
          [
            efmls-configs-nvim
            fzf-lua
            mini-nvim
            nvim-lspconfig
            nvim-treesitter-context
            nvim-treesitter-refactor
            nvim-treesitter-textobjects
            nvim-treesitter.withAllGrammars
            oil-nvim
            snippets-nvim
            vim-dispatch
            vim-eunuch
            vim-fugitive
          ]
          ++ lib.optionals rustSupport [
            # currently broken: https://github.com/NixOS/nixpkgs/issues/333761
            # # Use rustaceanvim for single-file support. See
            # # https://github.com/neovim/nvim-lspconfig/issues/1528.
            # rustaceanvim
          ]
        )
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
              fd # picker
              fswatch # TODO(jared): remove when the following is released: https://github.com/neovim/neovim/commit/55e4301036bb938474fc9768c41e28df867d9286
              inotify-tools # for faster LSP experience
              fzf # fzf-lua
              git # mini-git
              git-extras # :Permalink
              ripgrep # picker
              tree-sitter
              xdg-utils # :Permalink
            ]
            ++ (lib.optionals cSupport [ clang-tools ])
            ++ (lib.optionals goSupport [
              go-tools
              gofumpt
              gopls
            ])
            ++ (lib.optionals haskellSupport [
              ghc
              haskell-language-server
              ormolu
            ])
            ++ (lib.optionals latexSupport [
              (texlive.combine { inherit (texlive) scheme-minimal latexindent; })
            ])
            ++ (lib.optionals luaSupport [ lua-language-server ])
            ++ (lib.optionals nixSupport [
              nil
              nixfmt-rfc-style
            ])
            ++ (lib.optionals rustSupport [
              rust-analyzer
              rustc
              rustfmt
            ])
            ++ (lib.optionals shellSupport [
              shellcheck
              shfmt
            ])
            ++ (lib.optionals tomlSupport [ taplo ])
            ++ (lib.optionals zigSupport [ zls ])
            ++ (lib.optionals pythonSupport [
              pyright
              ruff
            ])
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
