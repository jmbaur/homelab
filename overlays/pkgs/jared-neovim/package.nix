{
  direnv,
  bash-language-server,
  clang-tools,
  curl,
  dtc,
  fd,
  fzf,
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
  nushell,
  pyright,
  ripgrep,
  ruff,
  runCommand,
  rust-analyzer,
  rustfmt,
  shellcheck,
  shfmt,
  stylua,
  ttags,
  vimPlugins,
  vimUtils,
  wrapNeovimUnstable,
  writeShellScriptBin,
  writeText,
  yaml-language-server,
  zls,
  supportAllLanguages ? false,
  cSupport ? supportAllLanguages,
  goSupport ? supportAllLanguages,
  luaSupport ? supportAllLanguages,
  nixSupport ? supportAllLanguages,
  nushellSupport ? supportAllLanguages,
  pythonSupport ? supportAllLanguages,
  rustSupport ? supportAllLanguages,
  shellSupport ? supportAllLanguages,
  yamlSupport ? supportAllLanguages,
  zigSupport ? supportAllLanguages,
}:
let
  dtc_vim = writeShellScriptBin "dtc_vim" ''
    # Use getopts to dismiss '--' args
    while getopts "" _; do
      true
    done

    file="''${@:$OPTIND:1}"

    if [[ "$file" == *.dtb ]]; then
      ${lib.getExe dtc} -I dtb -O dts -o "''${file//.dtb}" "$file"
    else
      ${lib.getExe dtc} -I dts -O dtb -o "''${file}.dtb" "$file"
    fi

    rm -f "$file"
  '';

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
            nushellSupport
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
    dependencies = with vimPlugins; [
      direnv-vim
      fzf-lua
      gruvbox-nvim
      mini-nvim
      none-ls-nvim
      nvim-lspconfig
      nvim-treesitter-context
      nvim-treesitter-refactor
      nvim-treesitter-textobjects
      nvim-treesitter.withAllGrammars
      oil-nvim
      vim-dispatch
      vim-eunuch
      vim-fugitive
    ];
    src = runCommand "jmbaur-nvim-config-src" { } ''
      cp -r --no-preserve=mode ${./settings} $out
      sed -i "3ivim.cmd.source(\"${langSupportLua}\")\n" $out/lua/init.lua
    '';
  };

  config = neovimUtils.makeNeovimConfig {
    plugins = [ jmbaur-config ];
  };

  binPath = lib.makeBinPath (
    [
      curl # :Permalink
      direnv # direnv-vim
      dtc_vim # gzip#read("dtc_vim"), gzip#write("dtc_vim")
      fd # fzf-lua
      fzf # fzf-lua
      git # fugitive, mini-git
      inotify-tools # for faster LSP experience
      ripgrep # picker
      ttags # LSP to create tags for a few different languages
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
    ++ (lib.optionals nushellSupport [ nushell ])
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
