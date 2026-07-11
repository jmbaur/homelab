{
  bash-language-server,
  runCommand,
  clang-tools,
  dts-lsp,
  fd,
  fennel-ls,
  fetchFromGitHub,
  fnlfmt,
  gitMinimal,
  go-tools,
  gofumpt,
  gopls,
  lib,
  lua-language-server,
  neovim-unwrapped,
  nix-prefetch-github,
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
  tree-sitter-grammars,
  ttags,
  typescript-go,
  vimPlugins,
  vimUtils,
  wrapNeovimUnstable,
  writeShellScriptBin,
  zig_0_16,
  zls_0_16,
}:

(wrapNeovimUnstable
  (neovim-unwrapped.overrideAttrs {
    version = "v0.13.0-dev";
    src = fetchFromGitHub (lib.importJSON ./src.json);
    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      mv $out/share/applications/org.neovim.nvim.desktop $out/share/applications/nvim.desktop
    '';
  })
  {
    customRC = "set exrc";

    extraLuaPackages = ps: [ ps.fennel ];

    vimAlias = true;

    plugins = [
      (vimUtils.buildVimPlugin {
        pname = "nvim-tree-sitter";
        version = "0.0.0";
        src = runCommand "nvim-tree-sitter-src" { } ''
          mkdir -p $out/plugin $out/parser $out/queries/lua
          mkdir -p $out/parser
          ${lib.concatMapStringsSep "\n" (
            grammar:
            let
              name = lib.strings.replaceStrings [ "-" ] [ "_" ] (
                lib.strings.removePrefix "tree-sitter-" (
                  lib.strings.removeSuffix "-grammar" (lib.strings.getName grammar)
                )
              );
            in
            ''
              install -Dm0644 ${grammar}/parser $out/parser/${name}.so
              echo 'vim.treesitter.language.add("${name}")' >> $out/plugin/init.lua
              if [[ -d ${grammar}/queries ]]; then
                cp -r ${grammar}/queries $out/queries/${name}
              else
                echo "lang ${name} does not have any queries!"
              fi
            ''
          ) tree-sitter-grammars.allGrammars}
        '';
      })
      (vimUtils.buildVimPlugin {
        pname = "jared-neovim-config";
        version = "0.0.0";
        src = ./nvim;
        buildPhase = ''
          make -j$NIX_BUILD_CORES install
        '';
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
          ttags
          typescript-go
          zig_0_16
          zls_0_16
        ];
      })
    ]
    ++ (with vimPlugins; [
      direnv-vim
      fennel-vim
      modus-themes-nvim
      nvim-lspconfig
      readline-vim
      vim-dispatch
      vim-eunuch
      vim-fugitive
      vim-surround
      vim-vinegar
    ]);
  }
).overrideAttrs
  (old: {
    passthru = old.passthru or { } // {
      updateScript = writeShellScriptBin "neovim-master-update" ''
        ${lib.getExe' nix-prefetch-github "nix-prefetch-github"} neovim neovim \
          >| $(${lib.getExe gitMinimal} rev-parse --show-toplevel)/overlays/by-name/jared-neovim/src.json
      '';
    };
  })
