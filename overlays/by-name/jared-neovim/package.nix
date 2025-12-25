{
  clang-tools,
  dts-lsp,
  fd,
  fennel-ls,
  fetchFromGitHub,
  fnlfmt,
  fzf,
  go-tools,
  gofumpt,
  gopls,
  lib,
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
  zig_0_15,
  zls_0_15,
}:

let
  neovim = neovim-unwrapped.overrideAttrs (
    assert (
      lib.assertMsg (
        !lib.versionAtLeast neovim-unwrapped.version "0.12.0"
      ) "Neovim version from nixpkgs is already 0.12.0"
    );
    {
      version = "0.12.0";
      src = fetchFromGitHub {
        owner = "neovim";
        repo = "neovim";
        rev = "5a1a92cc7a3d3a338fe5f610190910e220f074f6";
        hash = "sha256-kTaJ3AQ+yPvk1vs5wNHaw8uNxLKp4e2t49ZM7t4QZuE=";
      };
    }
  );
in
wrapNeovimUnstable neovim (
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
          find $out -name '*.fnl' -o -name 'Makefile' -delete
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
          zig_0_15
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
