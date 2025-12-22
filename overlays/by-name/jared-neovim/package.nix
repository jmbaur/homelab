{
  clang-tools,
  dts-lsp,
  fd,
  fennel-ls,
  fnlfmt,
  fzf,
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
  tex-fmt,
  texlab,
  texlive,
  tofu-ls,
  ttags,
  vimPlugins,
  vimUtils,
  wrapNeovimUnstable,
  zig,
  zls_0_15,
}:

wrapNeovimUnstable neovim-unwrapped (
  neovimUtils.makeNeovimConfig {
    customRC = "set exrc";

    extraLuaPackages = ps: [ ps.fennel ];

    withNodeJs = false;
    withPerl = false;
    withRuby = false;

    vimAlias = true;

    plugins = [
      (vimUtils.buildVimPlugin {
        name = "jared-neovim-config";
        src = ./nvim;
        buildPhase = "make -j$NIX_BUILD_CORES";
        postInstall = ''
          find $out -name '*.fnl' -delete
          rm $out/Makefile
        '';
        nativeBuildInputs = [ pkgsBuildBuild.neovim-unwrapped.lua.pkgs.fennel ];
        runtimeDeps = [
          clang-tools
          dts-lsp
          fd
          fennel-ls
          fnlfmt
          fzf
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
          ttags
          zig
          zls_0_15
        ];
      })
    ]
    ++ (with vimPlugins; [
      bpftrace-vim
      conjure
      fzf-lua
      mini-nvim
      nvim-lspconfig
      nvim-paredit
      nvim-treesitter.withAllGrammars
      vim-dispatch
      vim-eunuch
      vim-fugitive
      vim-rsi
      vim-surround
      vim-vinegar
      zoxide-vim
    ]);
  }
)
