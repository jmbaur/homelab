{
  clang-tools,
  dts-lsp,
  fd,
  fzf,
  go-tools,
  gofumpt,
  gopls,
  lua-language-server,
  neovim-unwrapped,
  neovimUtils,
  nil,
  nixfmt,
  pyright,
  ripgrep,
  ruff,
  rust-analyzer,
  rustfmt,
  shellcheck,
  shfmt,
  ttags,
  vimPlugins,
  vimUtils,
  wrapNeovimUnstable,
  zig,
  zls,
}:

wrapNeovimUnstable neovim-unwrapped (
  neovimUtils.makeNeovimConfig {
    customRC = "set exrc";

    withNodeJs = false;
    withPerl = false;
    withRuby = false;

    vimAlias = true;

    plugins = [
      (vimUtils.buildVimPlugin {
        name = "jared-neovim-config";
        src = ./nvim;
        runtimeDeps = [
          clang-tools
          dts-lsp
          fd
          fzf
          go-tools
          gofumpt
          gopls
          lua-language-server
          nil
          nixfmt
          pyright
          ripgrep
          ruff
          rust-analyzer
          rustfmt
          shellcheck
          shfmt
          ttags
          zig
          zls
        ];
      })
    ]
    ++ (with vimPlugins; [
      bpftrace-vim
      fzf-lua
      mini-nvim
      nvim-lspconfig
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
