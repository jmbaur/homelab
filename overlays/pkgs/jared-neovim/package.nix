{
  bash-language-server,
  bat,
  clang-tools,
  curl,
  fd,
  fswatch,
  git,
  go-tools,
  gofumpt,
  gopls,
  inotify-tools,
  lib,
  lua-language-server,
  neovim-unwrapped,
  neovimUtils,
  nil,
  nixfmt-rfc-style,
  pyright,
  ripgrep,
  ruff,
  runCommand,
  rust-analyzer,
  rustfmt,
  shellcheck,
  shfmt,
  skim,
  stylua,
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
  luaSupport ? supportAllLanguages,
  nixSupport ? supportAllLanguages,
  pythonSupport ? supportAllLanguages,
  rustSupport ? supportAllLanguages,
  shellSupport ? supportAllLanguages,
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
            luaSupport
            nixSupport
            pythonSupport
            rustSupport
            shellSupport
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
          mini-nvim
          none-ls-nvim
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
    ++ (lib.optionals luaSupport [
      lua-language-server
      stylua
    ])
    ++ (lib.optionals nixSupport [
      nil
      nixfmt-rfc-style
    ])
    ++ (lib.optionals rustSupport [
      rust-analyzer
      rustfmt
    ])
    ++ (lib.optionals shellSupport [
      bash-language-server
      shellcheck
      shfmt
    ])
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
