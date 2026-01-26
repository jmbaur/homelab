{
  bash-language-server,
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
  typescript-go,
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
        rev = "95b03171df223e1fed5de15124a3b9204f37048a";
        hash = "sha256-NCsf5TVBTHR0cMs1yVjfUHiRB89+faHV4Ls+ZXeMNmI=";
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
        depsBuildBuild = [ pkgsBuildBuild.neovim-unwrapped.lua.pkgs.fennel ];
        runtimeDeps = [
          bash-language-server
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
          typescript-go
          zig_0_15
          zls_0_15
        ];
      })
    ]
    ++ (with vimPlugins; [
      # TODO(jared): get this working nicely
      # conjure

      # TODO(jared): remove when we have https://github.com/ibhagwan/fzf-lua/pull/2501
      (fzf-lua.overrideAttrs {
        src = fetchFromGitHub {
          owner = "ibhagwan";
          repo = "fzf-lua";
          rev = "b8d1356b7120f5cf111709cb2fa504096248fb26";
          hash = "sha256-KNtnowiuudPH7g9EpF65n3JNbFL5cIDMP9LIrnvcL7k=";
        };
      })

      modus-themes-nvim
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
