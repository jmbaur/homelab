{
  bat,
  clang-tools,
  curl,
  efm-langserver,
  fd,
  fswatch,
  ghc,
  git,
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
  rustfmt,
  shellcheck,
  shfmt,
  skim,
  taplo,
  tex-fmt,
  tree-sitter,
  vimPlugins,
  vimUtils,
  wrapNeovimUnstable,
  writeText,
  yaml-language-server,
  zf,
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
  yamlSupport ? supportAllLanguages,
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
            yamlSupport
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
        ([
          efmls-configs-nvim
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
          transparent-nvim
          vim-dispatch
          vim-eunuch
          vim-fugitive
        ])
        # opt
        ++ (map (plugin: {
          inherit plugin;
          optional = true;
        }) [ fzf-lua ])
      );
  };

  binPath = lib.makeBinPath (
    [
      bat # fzf-lua/telescope
      curl # :Permalink
      efm-langserver
      fd # picker
      fswatch # TODO(jared): remove when the following is released: https://github.com/neovim/neovim/commit/55e4301036bb938474fc9768c41e28df867d9286
      git # fugitive, mini-git
      inotify-tools # for faster LSP experience
      ripgrep # picker
      skim # fzf-lua
      zf # telescope
      tree-sitter
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
    ++ (lib.optionals latexSupport [ tex-fmt ])
    ++ (lib.optionals luaSupport [ lua-language-server ])
    ++ (lib.optionals nixSupport [
      nil
      nixfmt-rfc-style
    ])
    ++ (lib.optionals rustSupport [
      rust-analyzer
      rustfmt
    ])
    ++ (lib.optionals shellSupport [
      shellcheck
      shfmt
    ])
    ++ (lib.optionals tomlSupport [ taplo ])
    ++ (lib.optionals yamlSupport [ yaml-language-server ])
    ++ (lib.optionals zigSupport [ zls ])
    ++ (lib.optionals pythonSupport [
      pyright
      ruff
    ])
  );

in
(wrapNeovimUnstable neovim-unwrapped (
  config
  // {
    vimAlias = true;
    # Disable wrapRc since it adds a `-u` flag to nvim, causing stuff like exrc
    # to not work OOTB.
    wrapRc = false;
    wrapperArgs = config.wrapperArgs ++ [
      # Append shell path with tools so that whatever we have in our
      # environment has precedence.
      "--suffix"
      "PATH"
      ":"
      binPath
    ];
  }
)).overrideAttrs
  (old: {
    postBuild =
      (old.postBuild or "")
      # remove desktop entry, this is a terminal application!
      + ''
        rm -rf $out/share/applications
      '';
  })
