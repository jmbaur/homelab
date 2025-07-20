{
  clang-tools,
  fd,
  fzf,
  go-tools,
  gofumpt,
  gopls,
  lua-language-server,
  neovim-unwrapped,
  neovimUtils,
  nil,
  nixfmt-rfc-style,
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
  zls,
}:

wrapNeovimUnstable neovim-unwrapped (
  neovimUtils.makeNeovimConfig {
    customRC = "set exrc";

    withNodeJs = false;
    withPerl = false;
    withRuby = false;

    vimAlias = true;

    plugins =
      [
        (vimUtils.buildVimPlugin {
          name = "jared-neovim-config";
          src = ./nvim;
          runtimeDeps = [
            clang-tools
            fd
            fzf
            go-tools
            gofumpt
            gopls
            nixfmt-rfc-style
            lua-language-server
            nil
            pyright
            ripgrep
            ruff
            rust-analyzer
            rustfmt
            shellcheck
            shfmt
            ttags
            zls
          ];
        })
      ]
      ++ (with vimPlugins; [
        bpftrace-vim
        fzf-lua
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
