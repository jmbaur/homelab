{
  bash-language-server,
  clang-tools,
  dts-lsp,
  fd,
  fennel-ls,
  fetchFromGitea,
  fzy,
  fnlfmt,
  go-tools,
  gofumpt,
  gopls,
  lua-language-server,
  neovim-unwrapped,
  nixd,
  nixfmt,
  pkgsBuildBuild,
  pyright,
  ripgrep,
  ruff,
  rust-analyzer,
  rustfmt,
  shellcheck,
  shfmt,
  sops,
  tex-fmt,
  texlab,
  texlive,
  tofu-ls,
  tree-sitter,
  ttags,
  typescript,
  vimPlugins,
  vimUtils,
  wrapNeovimUnstable,
  zig_0_16,
  zigscient,
  zls_0_16,
}:

wrapNeovimUnstable neovim-unwrapped {
  customRC = "set exrc";

  extraLuaPackages = ps: [ ps.fennel ];

  vimAlias = true;

  plugins = [
    (vimUtils.buildVimPlugin {
      pname = "jared-neovim-config";
      version = "0.0.0";
      src = ./nvim;
      buildPhase = "make -j$NIX_BUILD_CORES install";
      dontInstall = true;
      depsBuildBuild = [ pkgsBuildBuild.neovim-unwrapped.lua.pkgs.fennel ];
      runtimeDeps = [
        bash-language-server
        clang-tools
        dts-lsp
        fd
        fennel-ls
        fnlfmt
        go-tools
        gofumpt
        gopls
        lua-language-server
        nixd
        nixfmt
        pyright
        ripgrep
        ruff
        rust-analyzer
        rustfmt
        shellcheck
        shfmt
        sops
        tex-fmt
        texlab
        texlive.pkgs.latexmk
        tofu-ls
        tree-sitter
        ttags
        typescript
        zig_0_16
        zigscient
        zls_0_16
      ];
    })
  ]
  ++ [
    (vimUtils.buildVimPlugin {
      pname = "nvim-fzy";
      version = "0-unstable-2025-03-26";
      src = fetchFromGitea {
        domain = "codeberg.org";
        owner = "mfussenegger";
        repo = "nvim-fzy";
        rev = "cc41ba47d2f82c05cbf3a05b24dee325f8a96e1a";
        hash = "sha256-XibxiD2ZPcipn3P9Ziiao2C0wZMLGZleBnHQe3xJoMA=";
      };
      runtimeDeps = [ fzy ];
    })
    (vimUtils.buildVimPlugin {
      pname = "nvim-qwahl";
      version = "0-unstable-2025-05-22";
      src = fetchFromGitea {
        domain = "codeberg.org";
        owner = "mfussenegger";
        repo = "nvim-qwahl";
        rev = "3081cdd8fcbccfbe68381088ed0d6e1ff47da3a6";
        hash = "sha256-3sb87m9Anb32CVNecr+2Y+XmqZ0GEUo84hervVmcjdM=";
      };
    })
  ]
  ++ (with vimPlugins; [
    (readline-vim.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./readline-vim-c-y-pum.patch ];
    }))
    conjure
    direnv-vim
    fennel-vim
    modus-themes-nvim
    nvim-lspconfig
    nvim-treesitter.withAllGrammars
    vim-dispatch
    vim-eunuch
    vim-fugitive
    vim-surround
    vim-vinegar
  ]);
}
