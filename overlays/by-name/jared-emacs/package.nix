{
  bash-language-server,
  buildEnv,
  clang-tools,
  dts-lsp,
  emacs-pgtk,
  fd,
  fennel-ls,
  fetchFromGitHub,
  fnlfmt,
  go-tools,
  gofumpt,
  gopls,
  lua-language-server,
  nixd,
  nixfmt,
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
  ttags,
  zig_0_16,
  zls_0_16,
}:

let
  emacs = emacs-pgtk.pkgs.withPackages (epkgs: [
    (
      if stdenv.hostPlatform.isDarwin then
        epkgs.vterm
      else
        (epkgs.ghostel.overrideAttrs (old: {
          packageRequires = [ epkgs.evil ];
          preBuild = (old.preBuild or "") + ''
            cp extensions/evil-ghostel/evil-ghostel.el lisp
          '';
        }))
    )
    (epkgs.melpaBuild (_finalAttrs: {
      pname = "rail";
      version = "0.4.0";

      src = fetchFromGitHub {
        owner = "Sasanidas";
        repo = "Rail";
        rev = "04e306bcdff11b54807203ca3bea85f4645633d1";
        hash = "sha256-HSeD20A0yqbs4QjuP/kHQM3Glu/CIse7iP+yFCGFD5k=";
      };
    }))
    epkgs.company
    epkgs.direnv
    epkgs.dts-mode
    epkgs.evil
    epkgs.evil-collection
    epkgs.evil-commentary
    epkgs.evil-numbers
    epkgs.evil-surround
    epkgs.exec-path-from-shell
    epkgs.fennel-mode
    epkgs.geiser
    epkgs.git-link
    epkgs.go-mode
    epkgs.goto-chg
    epkgs.haskell-mode
    epkgs.janet-mode
    epkgs.lua-mode
    epkgs.magit
    epkgs.markdown-mode
    epkgs.meson-mode
    epkgs.nix-mode
    epkgs.racket-mode
    epkgs.rg
    epkgs.rust-mode
    epkgs.slime
    epkgs.sops
    epkgs.terraform-mode
    epkgs.typescript-mode
    epkgs.yaml-mode
    epkgs.zig-mode
  ]);
in
buildEnv {
  name = "jared-emacs";
  meta.mainProgram = "emacs";
  paths = [
    bash-language-server
    clang-tools
    dts-lsp
    emacs
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
    zig_0_16
    zls_0_16
  ];
}
