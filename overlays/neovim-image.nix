{ dockerTools
, buildEnv
, runtimeShell
, busybox
, bat
, black
, clang-tools
, clippy
, deno
, fd
, go
, git
, go-tools
, gofumpt
, gopls
, html-tidy
, neovim
, nil
, nixpkgs-fmt
, nodePackages
, pyright
, ripgrep
, rust-analyzer
, rustfmt
, shellcheck
, shfmt
, skim
, sumneko-lua-language-server
, taplo
, tmux
, tree-sitter
, yamlfmt
, zls
, cargo
, rustc
, ...
}:
dockerTools.buildImage {
  name = "neovim";
  tag = "latest";

  runAsRoot = ''
    #!${runtimeShell}
    mkdir -p /tmp
  '';

  copyToRoot = buildEnv {
    name = "development-environment";
    paths = [
      bat
      black
      busybox
      cargo
      clang-tools
      clippy
      deno
      fd
      fd
      git
      go
      go-tools
      gofumpt
      gopls
      html-tidy
      neovim
      nil
      nixpkgs-fmt
      nodePackages.typescript-language-server
      pyright
      ripgrep
      rust-analyzer
      rustc
      rustfmt
      shellcheck
      shfmt
      skim
      sumneko-lua-language-server
      taplo
      tmux
      tree-sitter
      yamlfmt
      zls
    ];
    pathsToLink = [ "/bin" ];
  };

  config = {
    Cmd = [ "tmux" "new-session" "nvim" ];
    WorkingDir = "/build";
    Volumes = { "/build" = { }; };
  };
}
