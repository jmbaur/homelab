{
  bash-language-server,
  clang-tools,
  dts-lsp,
  fd,
  fennel-ls,
  fnlfmt,
  go-tools,
  gofumpt,
  gopls,
  lua-language-server,
  neovim-unwrapped,
  neovimUtils,
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
  stdenv,
  tex-fmt,
  texlab,
  texlive,
  tofu-ls,
  tree-sitter,
  ttags,
  typescript-go,
  vimPlugins,
  vimUtils,
  wrapNeovimUnstable,
  zig-neovim-unwrapped,
  zig_0_15,
  zls_0_15,
}:

wrapNeovimUnstable
  # zig neovim build on macos currently doesn't work
  (if stdenv.hostPlatform.isDarwin then neovim-unwrapped else zig-neovim-unwrapped)
  (
    neovimUtils.makeNeovimConfig {
      customRC = "set exrc";

      extraLuaPackages = ps: [ ps.fennel ];

      vimAlias = true;

      plugins = [
        (vimUtils.buildVimPlugin {
          name = "jared-neovim-config";
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
            tex-fmt
            texlab
            texlive.pkgs.latexmk
            tofu-ls
            tree-sitter
            ttags
            typescript-go
            zig_0_15
            zls_0_15
          ];
        })
      ]
      ++ (with vimPlugins; [
        direnv-vim
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
        vim-dispatch
        vim-eunuch
        vim-fugitive
        vim-rsi
        vim-surround
        vim-vinegar
      ]);
    }
  )
